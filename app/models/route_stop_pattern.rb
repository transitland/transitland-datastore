# == Schema Information
#
# Table name: current_route_stop_patterns
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  geometry                           :geography({:srid geometry, 4326
#  tags                               :hstore
#  stop_pattern                       :string           default([]), is an Array
#  version                            :integer
#  trips                              :string           default([]), is an Array
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  created_or_updated_in_changeset_id :integer
#  route_id                           :integer
#  stop_distances                     :float            default([]), is an Array
#  edited_attributes                  :string           default([]), is an Array
#  geometry_source                    :string
#
# Indexes
#
#  c_rsp_cu_in_changeset                              (created_or_updated_in_changeset_id)
#  index_current_route_stop_patterns_on_onestop_id    (onestop_id) UNIQUE
#  index_current_route_stop_patterns_on_route_id      (route_id)
#  index_current_route_stop_patterns_on_stop_pattern  (stop_pattern)
#  index_current_route_stop_patterns_on_trips         (trips)
#

class BaseRouteStopPattern < ActiveRecord::Base
  self.abstract_class = true

  attr_accessor :traversed_by
  attr_accessor :serves
end

class RouteStopPattern < BaseRouteStopPattern
  self.table_name_prefix = 'current_'

  COORDINATE_PRECISION = 5
  DISTANCE_PRECISION = 1
  OUTLIER_THRESHOLD = 100

  belongs_to :route
  has_many :schedule_stop_pairs
  validates :geometry, :stop_pattern, presence: true
  validates :onestop_id, uniqueness: true, on: create
  validate :has_at_least_two_stops,
    :geometry_has_at_least_two_coords,
    :correct_stop_distances_length

  extend Enumerize
  enumerize :geometry_source, in: [:trip_stop_points, :shapes_txt, :shapes_txt_with_dist_traveled, :user_edited]

  def has_at_least_two_stops
    if stop_pattern.length < 2
      errors.add(:stop_pattern, 'RouteStopPattern needs at least 2 stops')
    end
  end

  def geometry_has_at_least_two_coords
    if geometry.nil? || self[:geometry].num_points < 2
      errors.add(:geometry, 'RouteStopPattern needs a geometry with least 2 coordinates')
    end
  end

  def correct_stop_distances_length
    if stop_pattern.size != stop_distances.size
      errors.add(:stop_distances, 'RouteStopPattern stop_distances size must equal stop_pattern size')
    end
  end

  include HasAOnestopId
  include HasAGeographicGeometry
  include HasTags
  include UpdatedSince
  include IsAnEntityImportedFromFeeds
  include IsAnEntityWithIssues

  # Tracked by changeset
  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :onestop_entity,
    virtual_attributes: [
      :traversed_by,
      :add_imported_from_feeds,
      :not_imported_from_feeds
    ],
    protected_attributes: [],
    sticky_attributes: [
      :geometry
    ]
  })

  def update_associations(changeset)
    if self.traversed_by
      route = Route.find_by_onestop_id!(self.traversed_by)
      self.update_columns(route_id: route.id)
    end
    update_entity_imported_from_feeds(changeset)
    super(changeset)
  end

  # borrowed from schedule_stop_pair.rb
  def self.find_by_attributes(attrs = {})
    if attrs[:id].present?
      find(attrs[:id])
    end
  end

  def self.line_string(points)
    RouteStopPattern::GEOFACTORY.line_string(
      points.map {|lon, lat| RouteStopPattern::GEOFACTORY.point(lon, lat)}
    )
  end

  def self.set_precision(points)
    points.map { |c| c.map { |n| n.round(COORDINATE_PRECISION) } }
  end

  def nearest_point(locators, nearest_seg_index)
    locators[nearest_seg_index].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326))
  end

  def nearest_segment_index(locators, point, s, e, first=true, side_filter=false, side=1)
    # 'side' must be positive or negative, but not zero. positive
    # will match targets to the right of the segment direction; negative left.
    side *= -1 # there seems to be a bug in RGeo which gives the reverse of the documented value.
    if side_filter
      results = locators[s..e].select { |locator|  locator.segment.side(point)*side >= 0 }
      results = locators[s..e] if results.empty?
    else
      results = locators[s..e]
    end
    if first
      seg_distances = results.map(&:distance_from_segment)
      # make sure to get the first minimum if 'first' is true and there are multiple values
      s + seg_distances.index(seg_distances.min)
    else
      seg_distances = results.map(&:distance_from_segment)
      # otherwise get the last minimum if there are multiple values
      s + seg_distances.rindex(seg_distances.min)
    end
  end

  def distance_along_line_to_nearest(cartesian_route, nearest_point, nearest_seg_index)
    if nearest_seg_index == 0
      points = [cartesian_route.coordinates[0], [nearest_point.x, nearest_point.y]]
    else
      points = cartesian_route.line_subset(0, nearest_seg_index-1).coordinates << [nearest_point.x, nearest_point.y]
    end
    RouteStopPattern.line_string(points).length
  end

  def distance_to_nearest_point(stop_point_spherical, nearest_point)
    stop_point_spherical[:geometry].distance(RGeo::Feature.cast(nearest_point, RouteStopPattern::GEOFACTORY))
  end

  def test_distance(distance)
    distance < OUTLIER_THRESHOLD
  end

  def fallback_distances(stops=nil)
    self.stop_distances = [0.0]
    total_distance = 0.0
    stops = self.stop_pattern.map {|onestop_id| Stop.find_by_onestop_id!(onestop_id) } if stops.nil?
    stops.each_cons(2) do |stop1, stop2|
      total_distance += stop1[:geometry].distance(stop2[:geometry])
      self.stop_distances << total_distance
    end
    self.stop_distances.map!{ |distance| distance.round(DISTANCE_PRECISION) }
  end

  def gtfs_shape_dist_traveled(stop_times, tl_stops, shape_distances_traveled)
    # assumes stop times and shapes BOTH have shape_dist_traveled, and they're in the same units
    # assumes the line geometry is not generated, and shape_points equals the rsp geometry.
    self.stop_distances = []
    stop_times.each_with_index do |st, i|
      stop_onestop_id = self.stop_pattern[i]
      # Find segment along shape points where stop shape_dist_traveled is between the two shape points' shape_dist_traveled
      dist1, dist2 = shape_distances_traveled.zip(shape_distances_traveled[1..-1]).detect do |d1, d2|
        st.shape_dist_traveled.to_f >= d1 && st.shape_dist_traveled.to_f <= d2
      end
      seg_index = shape_distances_traveled.index(dist1) # distances should always be increasing
      cartesian_line = cartesian_cast(self[:geometry])
      stop = tl_stops[i]
      nearest_point_on_line = cartesian_line.closest_point_on_segment(cartesian_cast(stop[:geometry]), seg_index)
      self.stop_distances << distance_along_line_to_nearest(cartesian_line, nearest_point_on_line, seg_index)
    end
    self.stop_distances.map!{ |distance| distance.round(DISTANCE_PRECISION) }
  end

  def calculate_distances(stops=nil)
    if stops.nil?
      stop_hash = Hash[Stop.find_by_onestop_ids!(self.stop_pattern).map { |s| [s.onestop_id, s] }]
      stops = self.stop_pattern.map{|s| stop_hash.fetch(s) }
    end
    if stops.map(&:onestop_id).uniq.size == 1
      self.stop_distances = Array.new(stops.size).map{|i| 0.0}
      return self.stop_distances
    end
    self.stop_distances = []
    route = cartesian_cast(self[:geometry])
    num_segments = route.coordinates.size - 1
    a = 0
    b = 0
    c = 0
    last_stop_after_geom = route.after?(stops[-1][:geometry]) || outlier_stop(stops[-1][:geometry])
    stops.each_index do |i|
      stop_spherical = stops[i]
      this_stop = cartesian_cast(stop_spherical[:geometry])
      if i == 0 && (route.before?(stops[i][:geometry]) || outlier_stop(this_stop))
        self.stop_distances << 0.0
        next
      elsif i == stops.size - 1
        if last_stop_after_geom
          self.stop_distances << self[:geometry].length
          break
        else
          c = num_segments - 1
        end
      else
        if (i + 1 == stops.size - 1) && last_stop_after_geom
          c = num_segments - 1
        else
          next_stop_spherical = stops[i+1]
          next_stop = cartesian_cast(next_stop_spherical[:geometry])
          next_stop_locators = route.locators(next_stop)
          next_nearest_seg_index = nearest_segment_index(next_stop_locators, next_stop, a, num_segments-1, first=false)
          next_nearest_point = nearest_point(next_stop_locators, next_nearest_seg_index)
          distance_to_line = distance_to_nearest_point(next_stop_spherical, next_nearest_point)
          if test_distance(distance_to_line)
            c = next_nearest_seg_index
          else
            c = num_segments - 1
          end
        end
      end

      locators = route.locators(this_stop)
      b = nearest_segment_index(locators, this_stop, a, c)
      nearest_point = nearest_point(locators, b)
      distance = distance_along_line_to_nearest(route, nearest_point, b)
      # check to make sure the distance is increasing, other than the edge cases.
      # if not, we can do a retry with some segment-matching adjustments
      equivalent_stop = stops[i].onestop_id.eql?(stops[i-1].onestop_id) || stops[i][:geometry].eql?(stops[i-1][:geometry])
      if (i!=0 && distance <= self.stop_distances[i-1] && distance!=0.0 && !equivalent_stop)
        if a == num_segments-1
          b = nearest_segment_index(locators, this_stop, a, num_segments - 1)
        else
          b = nearest_segment_index(locators, this_stop, a + 1, num_segments - 1)
        end
        nearest_point = nearest_point(locators, b)
        distance = distance_along_line_to_nearest(route, nearest_point, b)
      end

      distance_to_line = distance_to_nearest_point(stop_spherical, nearest_point)
      if !test_distance(distance_to_line)
        if (i==0)
          self.stop_distances << 0.0
        elsif (i==stops.size-1)
          self.stop_distances << self[:geometry].length
        else
          # interpolate using half the distance between previous and next stop
          self.stop_distances << self.stop_distances[i-1] + stops[i-1][:geometry].distance(stops[i+1][:geometry])/2.0
        end
      else
        self.stop_distances << distance
      end
      a = b
    end
    self.stop_distances.map!{ |distance| distance.round(DISTANCE_PRECISION) }
  end

  def cartesian_cast(geometry)
    cartesian_factory = RGeo::Cartesian::Factory.new(srid: 4326)
    RGeo::Feature.cast(geometry, cartesian_factory)
  end

  def outlier_stop(spherical_stop)
    cartesian_line = cartesian_cast(self[:geometry])
    closest_point = cartesian_line.closest_point(cartesian_cast(spherical_stop))
    spherical_closest = RGeo::Feature.cast(closest_point, RouteStopPattern::GEOFACTORY)
    spherical_stop.distance(spherical_closest) > OUTLIER_THRESHOLD
  end

  scope :with_trips, -> (search_string) { where{trips.within(search_string)} }
  scope :with_all_stops, -> (search_string) { where{stop_pattern.within(search_string)} }
  scope :with_any_stops, -> (stop_onestop_ids) { where( "stop_pattern && ARRAY[?]::varchar[]", stop_onestop_ids ) }

  def ordered_ssp_trip_chunks(&block)
    if block
      ScheduleStopPair.where(route_stop_pattern: self).order(:trip, :origin_departure_time).slice_when { |s1, s2|
        !s1.trip.eql?(s2.trip)
      }.each {|trip_chunk| yield trip_chunk }
    end
  end

  def generate_onestop_id
    return 'r-9q9-asd-123456-abcdef'
    # OnestopId.handler_by_model(self.class).new(name: (self.try(:name) || "test"), geohash: "9q9").to_s
  end


  ##### FromGTFS ####
  def generate_onestop_id
    fail Exception.new('route required') unless self.route
    fail Exception.new('stop_pattern required') unless self.stop_pattern.presence
    fail Exception.new('geometry required') unless self.geometry
    onestop_id = OnestopId.handler_by_model(RouteStopPattern).new(
     route_onestop_id: self.route.onestop_id,
     stop_pattern: self.stop_pattern,
     geometry_coords: self.geometry[:coordinates]
    )
    onestop_id.to_s
  end

  def self.create_from_gtfs(trip, route_onestop_id, stop_pattern, trip_stop_points, shape_points)
    # both trip_stop_points and stop_pattern correspond to stop_times.
    # GTFSGraph should already filter out stop_times of size 0 or 1 (using filter_empty).
    # We can still have one unique stop, but must have at least 2 stop times.
    raise ArgumentError.new('Need at least two stops') if stop_pattern.length < 2
    # Rgeo produces nil if there is only one coordinate in the array
    rsp = RouteStopPattern.new(
      stop_pattern: stop_pattern,
    )
    if shape_points.present?
      rsp.geometry = self.line_string(self.set_precision(shape_points))
      rsp.geometry_source = shape_points.shape_dist_traveled.all? ? :shapes_txt_with_dist_traveled : :shapes_txt
    else
      rsp.geometry = self.line_string(self.set_precision(trip_stop_points))
      rsp.geometry_source = :trip_stop_points
    end
    onestop_id = OnestopId.handler_by_model(RouteStopPattern).new(
     route_onestop_id: route_onestop_id,
     stop_pattern: rsp.stop_pattern,
     geometry_coords: rsp.geometry[:coordinates]
    )
    rsp.onestop_id = onestop_id.to_s
    rsp.tags ||= {}
    rsp
  end
end

class OldRouteStopPattern < BaseRouteStopPattern
  include OldTrackedByChangeset
  include HasAGeographicGeometry
end
