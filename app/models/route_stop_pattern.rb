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
#  created_or_updated_in_changeset_id :integer
#  is_generated                       :boolean          default(FALSE)
#  is_modified                        :boolean          default(FALSE)
#  is_only_stop_points                :boolean          default(FALSE)
#  trips                              :string           default([]), is an Array
#  identifiers                        :string           default([]), is an Array
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  route_id                           :integer
#
# Indexes
#
#  index_current_route_stop_patterns_on_identifiers  (identifiers)
#  index_current_route_stop_patterns_on_route_id     (route_id)
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

  def stop_points
    self.stop_pattern.map {|s| Stop.find_by_onestop_id!(s).geometry[:coordinates]}
  end

  def calculate_distances
    # TODO: potential issue with nearest stop segment matching after subsequent stop
    # TODO: investigate 'boundary' lat/lng possibilities
    # TODO: document each branch (conditional)
    distances = []
    total_distance = 0.0
    cartesian_factory = RGeo::Cartesian::Factory.new
    cast_route = RGeo::Feature.cast(self[:geometry], cartesian_factory)
    geometry_endpoint_reached = false
    self.stop_pattern.each_index do |i|
      stop = Stop.find_by_onestop_id!(self.stop_pattern[i])
      cast_stop = RGeo::Feature.cast(stop[:geometry], cartesian_factory)
      if geometry_endpoint_reached
        previous_stop = Stop.find_by_onestop_id!(self.stop_pattern[i-1])
        total_distance += stop[:geometry].distance(previous_stop[:geometry])
        distances << total_distance
      else
        splits = cast_route.split_at_point(cast_stop)
        if splits[0].nil?
          if i == 0
            distances << 0.0
          else
            previous_stop = Stop.find_by_onestop_id!(self.stop_pattern[i-1])
            total_distance += stop[:geometry].distance(previous_stop[:geometry])
            distances << total_distance
          end
        else
          total_distance += RGeo::Feature.cast(splits[0], RouteStopPattern::GEOFACTORY).length
          distances << total_distance
          if splits[1].nil?
            geometry_endpoint_reached = true
          else
            cast_route = splits[1]
          end
        end
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
    # more evaluations can go here. e.g. has outlier stop
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
    # more inspections can go here
  end

  scope :with_trips, -> (search_string) { where{trips.within(search_string)} }
  scope :with_stops, -> (search_string) { where{stop_pattern.within(search_string)} }

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

  def self.find_rsp(route_onestop_id, import_rsp_hash, test_rsp)
    onestop_id = OnestopId.handler_by_model(RouteStopPattern).new(
      route_onestop_id: route_onestop_id,
      stop_pattern: test_rsp.stop_pattern,
      geometry_coords: test_rsp.geometry[:coordinates]
    ).to_s
    saved_rsp = RouteStopPattern.find_by_onestop_id(onestop_id)
    if saved_rsp
      return saved_rsp if self.compare_by_structure(test_rsp, saved_rsp)
    elsif import_rsp_hash.keys.include?(onestop_id)
      return import_rsp_hash[onestop_id] if self.compare_by_structure(test_rsp, import_rsp_hash[onestop_id])
    else
      test_rsp.onestop_id = onestop_id
      test_rsp
    end
  end

  private

  def self.compare_by_structure(test_rsp, candidate_rsp)
    # test if two given rsps have equivalent stop pattern and geometry
    test_rsp.stop_pattern.eql?(candidate_rsp.stop_pattern) && test_rsp.geometry[:coordinates].eql?(candidate_rsp.geometry[:coordinates])
  end
end

class OldRouteStopPattern < BaseRouteStopPattern
  include OldTrackedByChangeset
  include HasAGeographicGeometry
end
