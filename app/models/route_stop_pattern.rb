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
#
# Indexes
#
#  c_rsp_cu_in_changeset                              (created_or_updated_in_changeset_id)
#  index_current_route_stop_patterns_on_identifiers   (identifiers)
#  index_current_route_stop_patterns_on_onestop_id    (onestop_id)
#  index_current_route_stop_patterns_on_route_id      (route_id)
#  index_current_route_stop_patterns_on_stop_pattern  (stop_pattern)
#  index_current_route_stop_patterns_on_trips         (trips)
#

class BaseRouteStopPattern < ActiveRecord::Base
  self.abstract_class = true

  include IsAnEntityImportedFromFeeds

  attr_accessor :traversed_by
end

class RouteStopPattern < BaseRouteStopPattern
  self.table_name_prefix = 'current_'

  COORDINATE_PRECISION = 5
  DISTANCE_PRECISION = 1

  belongs_to :route
  has_many :schedule_stop_pairs
  validates :geometry, :stop_pattern, presence: true
  validates :onestop_id, uniqueness: true, on: create
  validate :has_at_least_two_stops,
    :geometry_has_at_least_two_coords

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

  include HasAOnestopId
  include IsAnEntityWithIdentifiers
  include HasAGeographicGeometry
  include HasTags
  include UpdatedSince

  # Tracked by changeset
  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :onestop_entity,
    virtual_attributes: [
      :imported_from_feed,
      :identified_by,
      :not_identified_by,
      :traversed_by
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

  def self.simplify_geometry(points)
    points = self.set_precision(points)
    self.remove_duplicate_points(points)
  end

  def self.set_precision(points)
    points.map { |c| c.map { |n| n.round(COORDINATE_PRECISION) } }
  end

  def self.remove_duplicate_points(points)
    points.chunk{ |c| c }.map(&:first)
  end

  def calculate_distances
    # TODO: potential issue with nearest stop segment matching after subsequent stop
    # TODO: investigate 'boundary' lat/lng possibilities
    distances = []
    total_distance = 0.0
    cartesian_factory = RGeo::Cartesian::Factory.new(srid: 4326)
    cast_route = RGeo::Feature.cast(self[:geometry], cartesian_factory)
    geometry_length = self[:geometry].length
    self.stop_pattern.each_index do |i|
      stop = Stop.find_by_onestop_id!(self.stop_pattern[i])
      cast_stop = RGeo::Feature.cast(stop[:geometry], cartesian_factory)
      splits = cast_route.split_at_point(cast_stop)
      if (splits[0].nil? && i != 0) || (splits[1].nil? && i != self.stop_pattern.size - 1)
        # only the first and last stops are expected to have 1 split result instead of 2
        # So this might be an outlier stop. Another possibility might be 2 consecutive stops
        # having the same coordinates.
        logger.info "stop #{stop.onestop_id}, number #{i+1}, within route stop pattern #{self.onestop_id} may be an outlier or indicate invalid geometry"
        # TODO add interpolated distance at halfway and split line there?
        # if so, will need to take into account case of 2 consecutive stops having same location.
        if (i == 0 && splits[1].nil?)
          distances << 0.0
        elsif (i == self.stop_pattern.size - 1 && splits[0].nil?)
          distances << geometry_length.round(DISTANCE_PRECISION)
        else
          distances << distances[i-1]
        end
      else
        if splits[0].nil?
          distances << 0.0
        else
          total_distance += RGeo::Feature.cast(splits[0], RouteStopPattern::GEOFACTORY).length
          distances << total_distance.round(DISTANCE_PRECISION)
        end
        if (i != 0 && distances[i-1] == distances[i])
          logger.info "stop #{self.stop_pattern[i]} has the same distance as #{self.stop_pattern[i-1]}, which may indicate a segment matching issue."
        end
        cast_route = splits[1]
      end
      if (distances[i] > geometry_length)
        logger.info "stop #{stop.onestop_id}, number #{i+1}, of route stop pattern #{self.onestop_id} has a distance greater than the length of the geometry"
      end
      if (i != 0 && distances[i-1] > distances[i])
        logger.info "stop #{self.stop_pattern[i]} occurs after stop #{self.stop_pattern[i-1]} but has a distance less than #{self.stop_pattern[i-1]}"
      end
    end
    distances
  end

  def cartesian_cast(geometry)
    cartesian_factory = RGeo::Cartesian::Factory.new(srid: 4326)
    RGeo::Feature.cast(geometry, cartesian_factory)
  end

  def outlier_stop(spherical_stop)
    cartesian_line = cartesian_cast(self[:geometry])
    closest_point = cartesian_line.closest_point(cartesian_cast(spherical_stop))
    spherical_closest = RGeo::Feature.cast(closest_point, RouteStopPattern::GEOFACTORY)
    spherical_stop.distance(spherical_closest) > 100.0
  end

  def evaluate_geometry(trip, stop_points)
    # makes judgements on geometry so modifications can be made by tl_geometry
    issues = []
    if trip.shape_id.nil? || self.geometry[:coordinates].empty?
      issues << :empty
    else
      cartesian_factory = RGeo::Cartesian::Factory.new(srid: 4326)
      cartesian_line = RGeo::Feature.cast(self[:geometry], cartesian_factory)
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
    if issues.include?(:empty)
      # create a new geometry from the trip stop points
      self.geometry = RouteStopPattern.line_string(RouteStopPattern.simplify_geometry(stop_points))
      self.is_generated = true
      self.is_modified = true
    end
    if issues.include?(:has_before_stop)
      points = self.geometry[:coordinates].unshift(RouteStopPattern.set_precision([stop_points[0]])[0])
      self.geometry = RouteStopPattern.line_string(RouteStopPattern.simplify_geometry(points))
      self.is_modified = true
    end
    if issues.include?(:has_after_stop)
      points = self.geometry[:coordinates] << RouteStopPattern.set_precision([stop_points[-1]])[0]
      self.geometry = RouteStopPattern.line_string(RouteStopPattern.simplify_geometry(points))
      self.is_modified = true
    end
    # more geometry modification can go here
  end

  scope :with_trips, -> (search_string) { where{trips.within(search_string)} }
  scope :with_stops, -> (search_string) { where{stop_pattern.within(search_string)} }

  ##### FromGTFS ####
  def self.create_from_gtfs(trip, route_onestop_id, stop_pattern, trip_stop_points, shape_points)
    raise ArgumentError.new('Need at least two stops') if stop_pattern.length < 2
    rsp = RouteStopPattern.new(
      stop_pattern: stop_pattern,
      geometry: self.line_string(self.simplify_geometry(shape_points))
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
    rsp.tags[:shape_id] = trip.shape_id
    rsp
  end
end

class OldRouteStopPattern < BaseRouteStopPattern
  include OldTrackedByChangeset
  include HasAGeographicGeometry
end
