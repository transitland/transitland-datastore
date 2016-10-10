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
#  is_generated                       :boolean          default(FALSE)
#  is_modified                        :boolean          default(FALSE)
#  trips                              :string           default([]), is an Array
#  identifiers                        :string           default([]), is an Array
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  created_or_updated_in_changeset_id :integer
#  route_id                           :integer
#  stop_distances                     :float            default([]), is an Array
#  edited_attributes                  :string           default([]), is an Array
#
# Indexes
#
#  c_rsp_cu_in_changeset                              (created_or_updated_in_changeset_id)
#  index_current_route_stop_patterns_on_identifiers   (identifiers)
#  index_current_route_stop_patterns_on_onestop_id    (onestop_id) UNIQUE
#  index_current_route_stop_patterns_on_route_id      (route_id)
#  index_current_route_stop_patterns_on_stop_pattern  (stop_pattern)
#  index_current_route_stop_patterns_on_trips         (trips)
#

class BaseRouteStopPattern < ActiveRecord::Base
  self.abstract_class = true

  attr_accessor :traversed_by, :first_stop_before_geom, :last_stop_after_geom
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
  include IsAnEntityWithIdentifiers
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
      :identified_by,
      :not_identified_by,
      :traversed_by
    ],
    protected_attributes: [
      :identifiers
    ],
    sticky_attributes: [
      :geometry
    ]
  })
  class << RouteStopPattern
    alias_method :existing_before_create_making_history, :before_create_making_history
  end
  def self.before_create_making_history(new_model, changeset)
    route = Route.find_by_onestop_id!(new_model.traversed_by)
    new_model.route = route
    self.existing_before_create_making_history(new_model, changeset)
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

  def nearest_segment_index_reverse(locators, s, e, threshold=false, point=nil)
    if threshold && point
      a = locators[s..e].reverse_each.map{ |loc| loc.interpolate_point(Stop::GEOFACTORY) }
      match_point = a.detect { |closest_point| closest_point.distance(point) < FIRST_MATCH_THRESHOLD }
      unless match_point.nil?
        return s + a.rindex(match_point)
      end
    end
    a = locators[s..e].map(&:distance_from_segment)
    s + a.rindex(a.min)
  end

  def nearest_segment_index_forward(locators, s, e, threshold=false, point=nil)
    if threshold && point
      a = locators[s..e].map{ |loc| loc.interpolate_point(Stop::GEOFACTORY) }
      match_point = a.detect { |closest_point| closest_point.distance(point) < FIRST_MATCH_THRESHOLD }
      unless match_point.nil?
        return s + a.index(match_point)
      end
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
    stops.each_index do |i|
      stop_spherical = stops[i]
      this_stop = cartesian_cast(stop_spherical[:geometry])
      if i == 0 && self.first_stop_before_geom
        self.stop_distances << 0.0
        next
      elsif i == stops.size - 1
        if self.last_stop_after_geom
          self.stop_distances << self[:geometry].length
          break
        else
          c = num_segments - 1
        end
      else
        if (i + 1 == stops.size - 1) && self.last_stop_after_geom
          c = num_segments - 1
        else
          next_stop_spherical = stops[i+1]
          next_stop = cartesian_cast(next_stop_spherical[:geometry])
          next_stop_locators = route.locators(next_stop)
          next_nearest_seg_index = nearest_segment_index_reverse(next_stop_locators, a, num_segments-1, threshold=true, point=next_stop_spherical[:geometry])
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
      b = nearest_segment_index_forward(locators, a, c)
      nearest_point = nearest_point(locators, b)
      distance = distance_along_line_to_nearest(route, nearest_point, b)
      if (i!=0 && distance <= self.stop_distances[i-1] && !stops[i].onestop_id.eql?(stops[i-1].onestop_id))
        if (a == num_segments - 1)
          b = nearest_segment_index_forward(locators, a, num_segments - 1)
        else
          b = nearest_segment_index_forward(locators, a + 1, num_segments - 1)
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

  def evaluate_geometry(trip, stop_points)
    # makes judgements on geometry so modifications can be made by tl_geometry
    issues = []
    if trip.shape_id.nil? || self.geometry.nil? || self.geometry[:coordinates].empty?
      issues << :empty
    else
      cartesian_line = cartesian_cast(self[:geometry])
      first_stop = RouteStopPattern::GEOFACTORY.point(stop_points[0][0],stop_points[0][1])
      if cartesian_line.before?(first_stop) || outlier_stop(first_stop)
        issues << :has_before_stop
      end
      last_stop = RouteStopPattern::GEOFACTORY.point(stop_points[-1][0],stop_points[-1][1])
      if cartesian_line.after?(last_stop) || outlier_stop(last_stop)
        issues << :has_after_stop
      end
    end
    # more evaluations can go here
    return (issues.size > 0), issues
  end

  def tl_geometry(stop_points, issues)
    # modify rsp geometry based on issues array from evaluate_geometry
    self.first_stop_before_geom = false
    self.last_stop_after_geom = false
    if issues.include?(:empty)
      # create a new geometry from the trip stop points
      self.geometry = RouteStopPattern.line_string(RouteStopPattern.set_precision(stop_points))
      self.is_generated = true
      self.is_modified = true
    end
    self.first_stop_before_geom = true if issues.include?(:has_before_stop)
    self.last_stop_after_geom = true if issues.include?(:has_after_stop)
    # more geometry modification can go here
  end

  scope :with_trips, -> (search_string) { where{trips.within(search_string)} }
  scope :with_stops, -> (search_string) { where{stop_pattern.within(search_string)} }

  def ordered_ssp_trip_chunks(&block)
    if block
      ScheduleStopPair.where(route_stop_pattern: self).order(:trip, :origin_departure_time).slice_when { |s1, s2|
        !s1.trip.eql?(s2.trip)
      }.each {|trip_chunk| yield trip_chunk }
    end
  end

  ##### FromGTFS ####
  def self.create_from_gtfs(trip, route_onestop_id, stop_pattern, trip_stop_points, shape_points)
    # both trip_stop_points and stop_pattern correspond to stop_times.
    # GTFSGraph should already filter out stop_times of size 0 or 1 (using filter_empty).
    # We can still have one unique stop, but must have at least 2 stop times.
    raise ArgumentError.new('Need at least two stops') if stop_pattern.length < 2
    # Rgeo produces nil if there is only one coordinate in the array
    rsp = RouteStopPattern.new(
      stop_pattern: stop_pattern,
      geometry: self.line_string(self.set_precision(shape_points))
    )
    has_issues, issues = rsp.evaluate_geometry(trip, trip_stop_points)
    rsp.tl_geometry(trip_stop_points, issues) if has_issues
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
