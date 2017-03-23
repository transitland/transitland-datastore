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
end

class RouteStopPattern < BaseRouteStopPattern
  self.table_name_prefix = 'current_'

  COORDINATE_PRECISION = 5
  DISTANCE_PRECISION = 1
  OUTLIER_THRESHOLD = 100
  FIRST_MATCH_THRESHOLD = 25

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

  def nearest_segment_index_forward(locators, s, e, point)
    closest_point_candidates = locators[s..e].map{ |loc| loc.interpolate_point(Stop::GEOFACTORY) }
    closest_point_and_dist = closest_point_candidates.map{ |closest_point|
      [closest_point, closest_point.distance(point)]
    }.detect { |closest_point_and_dist| closest_point_and_dist[1] < FIRST_MATCH_THRESHOLD }

    unless closest_point_and_dist.nil?
      dist = closest_point_and_dist[1]
      i = closest_point_candidates.index(closest_point_and_dist[0])
      if i != locators[s..e].size - 1
        next_seg_dist = locators[s..e][i+1].interpolate_point(Stop::GEOFACTORY).distance(point)
        while next_seg_dist < dist
          i += 1
          dist = next_seg_dist
          break if i == locators[s..e].size - 1
          next_seg_dist = locators[s..e][i+1].interpolate_point(Stop::GEOFACTORY).distance(point)
        end
      end
      return s + i
    end
    a = locators[s..e].map(&:distance_from_segment)
    s + a.index(a.min)
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
    # TODO consider using a more efficient search method?
    self.stop_distances = []
    stop_times.each_with_index do |st, i|
      stop_onestop_id = self.stop_pattern[i]
      # Find segment along shape points where stop shape_dist_traveled is between the two shape points' shape_dist_traveled
      seg_index = -1
      dist1, dist2 = shape_distances_traveled.each_cons(2).detect do |d1, d2|
        seg_index += 1
        st.shape_dist_traveled.to_f >= d1 && st.shape_dist_traveled.to_f <= d2
      end

      if dist1.nil? || dist2.nil?
        if st.shape_dist_traveled.to_f < shape_distances_traveled[0]
          self.stop_distances << 0.0
        elsif st.shape_dist_traveled.to_f > shape_distances_traveled[-1]
          self.stop_distances << self[:geometry].length
        else
          raise StandardError.new("Problem finding stop distance for Stop #{stop_onestop_id}, number #{i + 1} of RSP #{self.onestop_id} using shape_dist_traveled")
        end
      else
        cartesian_line = cartesian_cast(self[:geometry])
        stop = tl_stops[i]
        nearest_point_on_line = cartesian_line.closest_point_on_segment(cartesian_cast(stop[:geometry]), seg_index)
        self.stop_distances << distance_along_line_to_nearest(cartesian_line, nearest_point_on_line, seg_index)
      end
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
    c = num_segments - 1
    last_stop_after_geom = route.after?(stops[-1][:geometry]) || outlier_stop(stops[-1][:geometry])
    previous_stop_before_geom = false
    stops.each_index do |i|
      stop_spherical = stops[i]
      this_stop = cartesian_cast(stop_spherical[:geometry])
      if i == 0 && (route.before?(stops[i][:geometry]) || outlier_stop(this_stop))
        previous_stop_before_geom = true
        self.stop_distances << 0.0
      elsif i == stops.size - 1 && last_stop_after_geom
        self.stop_distances << self[:geometry].length
      else
        if (i + 1 < stops.size - 1)
          next_stop_spherical = stops[i+1]
          next_stop = cartesian_cast(next_stop_spherical[:geometry])
          next_stop_locators = route.locators(next_stop)
          next_candidates = next_stop_locators[a..num_segments-1].map(&:distance_from_segment)
          c = a + next_candidates.index(next_candidates.min)
        else
          c = num_segments - 1
        end

        locators = route.locators(this_stop)
        b = nearest_segment_index_forward(locators, a, c, this_stop)
        nearest_point = nearest_point(locators, b)

        # The next stop's match may be too early and restrictive, so allow more segment possibilities
        if distance_to_nearest_point(stop_spherical, nearest_point) > FIRST_MATCH_THRESHOLD
          if (i + 2 < stops.size - 1)
            next_stop_spherical = stops[i+2]
            next_stop = cartesian_cast(next_stop_spherical[:geometry])
            next_stop_locators = route.locators(next_stop)
            next_candidates = next_stop_locators[a..num_segments-1].map(&:distance_from_segment)
            c = a + next_candidates.index(next_candidates.min)
          else
            c = num_segments - 1
          end
          b = nearest_segment_index_forward(locators, a, c, this_stop)
          nearest_point = nearest_point(locators, b)
        end

        distance = distance_along_line_to_nearest(route, nearest_point, b)
        if (i!=0)
          if (route.before?(stops[i][:geometry]) || outlier_stop(this_stop)) && previous_stop_before_geom
            previous_stop_before_geom = true
          else
            equivalent_stop = stops[i].onestop_id.eql?(stops[i-1].onestop_id) || stops[i][:geometry].eql?(stops[i-1][:geometry])
            if !equivalent_stop && !previous_stop_before_geom
              # this can happen if this stop matches to the same segment as the previous
              while (distance <= self.stop_distances[i-1])
                if (a == num_segments - 1)
                  distance = self[:geometry].length
                  break
                end
                a += 1
                b = nearest_segment_index_forward(locators, a, c, this_stop)
                nearest_point = nearest_point(locators, b)
                distance = distance_along_line_to_nearest(route, nearest_point, b)
              end
            end
            previous_stop_before_geom = false
          end
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
    end # end stop pattern loop
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

  ##### FromGTFS ####
  def self.create_from_gtfs(trip, route_onestop_id, stop_pattern, stop_times, trip_stop_points, shape_points)
    # both trip_stop_points and stop_pattern correspond to stop_times.
    # GTFSGraph should already filter out stop_times of size 0 or 1 (using filter_empty).
    # We can still have one unique stop, but must have at least 2 stop times.
    raise ArgumentError.new('Need at least two stops') if stop_pattern.length < 2
    # Rgeo produces nil if there is only one coordinate in the array
    rsp = RouteStopPattern.new(
      stop_pattern: stop_pattern,
    )
    if shape_points.present? && shape_points.size > 1
      rsp.geometry = self.line_string(self.set_precision(shape_points))
      rsp.geometry_source = (stop_times.all?{ |st| st.shape_dist_traveled.present? } && shape_points.shape_dist_traveled.all?(&:present?)) ? :shapes_txt_with_dist_traveled : :shapes_txt
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
