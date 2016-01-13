# == Schema Information
#
# Table name: current_route_stop_patterns
#
#  id                                 :integer          not null, primary key
#  geometry                           :geography({:srid geometry, 4326
#  tags                               :hstore
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  stop_pattern                       :string           default([]), is an Array
#  version                            :integer
#  created_or_updated_in_changeset_id :integer
#  onestop_id                         :string
#  route_id                           :integer
#  route_type                         :string
#  is_generated                       :boolean          default(FALSE)
#  is_modified                        :boolean          default(FALSE)
#  is_only_stop_points                :boolean          default(FALSE)
#  trips                              :string           default([]), is an Array
#  identifiers                        :string           default([]), is an Array
#
# Indexes
#
#  index_current_route_stop_patterns_on_route_type_and_route_id  (route_type,route_id)
#

class BaseRouteStopPattern < ActiveRecord::Base
  self.abstract_class = true

  include IsAnEntityImportedFromFeeds

  attr_accessor :traversed_by
end

class RouteStopPattern < BaseRouteStopPattern
  self.table_name_prefix = 'current_'

  after_commit :inspect_geometry
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
    if geometry[:coordinates].length < 2
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

  def stop_points
    self.stop_pattern.map {|s| Stop.where(onestop_id: s).first.geometry[:coordinates]}
  end

  def calculate_distances
    # TODO: potential issue with nearest stop segment matching after subsequent stop
    # TODO: investigate 'boundary' lat/lng possibilities
    distances = []
    total_distance = 0.0
    cartesian_factory = RGeo::Cartesian::Factory.new
    cast_route = RGeo::Feature.cast(self[:geometry], cartesian_factory)
    self.stop_pattern.map {|s| Stop.find_by_onestop_id!(s)}.each do |stop|
      cast_stop = RGeo::Feature.cast(stop[:geometry], cartesian_factory)
      splits = cast_route.split_at_point(cast_stop)
      if !splits[0]
        distances << 0.0
      else
        total_distance += RGeo::Feature.cast(splits[0], RouteStopPattern::GEOFACTORY).length
        distances << total_distance
        cast_route = splits[1] || splits[0]
      end
    end
    distances
  end

  def evaluate_geometry(trip, stop_points)
    # makes judgements on geometry so modifications can be made by tl_geometry
    issues = {:empty => false, :has_outlier_stop => false}
    if trip.shape_id.nil? || self.geometry[:coordinates].empty?
      issues[:empty] = true
    end
    #polygon = RouteStopPattern.convex_hull([self], as: :wkt, projected: false)
    #stop_points.map {|coord| polygon.overlaps?() }
    # more inspections can go here
    issues
  end

  def tl_geometry(stop_points, issues)
    # modify rsp geometry based on issues hash from evaluate_geometry
    if issues[:empty]
      # create a new geometry from the trip stop points
      self.geometry = RouteStopPattern.line_string(stop_points)
      self.is_generated = true
      self.is_modified = true
    end
    # more geometry modification can go here
  end

  def inspect_geometry
    # find and record characteristics of the final geometry
    self.is_only_stop_points = false
    if Set.new(stop_points).eql?(Set.new(self.geometry[:coordinates]))
      self.is_only_stop_points = true
    end
    # more inspections will go here
  end

  ##### FromGTFS ####
  include FromGTFS
  def self.from_gtfs(trip, stop_pattern, shape_points)
    raise ArgumentError.new('Need at least two stops') if stop_pattern.length < 2
    rsp = RouteStopPattern.new(
      stop_pattern: stop_pattern,
      geometry: self.line_string(shape_points.uniq)
    )
    rsp.tags ||= {}
    rsp.tags[:shape_id] = trip.shape_id
    rsp
  end
end

class OldRouteStopPattern < BaseRouteStopPattern
  include OldTrackedByChangeset
  include HasAGeographicGeometry
end
