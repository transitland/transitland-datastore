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

  belongs_to :route #type for polymorphic association?
  has_many :schedule_stop_pairs
  validates :geometry, :stop_pattern, presence: true

  #include HasAOnestopId
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

  scope :route_onestop_id, -> (route_onestop_id) {
    where(route_id: Route.select(:id).where(onestop_id: route_onestop_id))
  }

  scope :unique_components_by_route_onestop_id, -> (rt_onestop_id, component_num) {
    route_onestop_id(rt_onestop_id).pluck(:onestop_id)
    .map {|f_id| f_id.split("#")[component_num]}.uniq
  }

  def self.generate_component_id(route_onestop_id, feed_onestop_ids, component)
    # S for stop_pattern, G for geometry
    component_num_hash = {'S' => 1, 'G' => 2}
    component_count = unique_components_by_route_onestop_id(route_onestop_id, component_num_hash[component]).size
    component_count += feed_onestop_ids.select {|f_id| f_id.split("#")[0] == route_onestop_id}
      .map {|f_id| f_id.split("#")[component_num_hash[component]]}.uniq.size
    "#{component}#{component_count + 1}"
  end

  def self.new_geometry(points)
    RouteStopPattern::GEOFACTORY.line_string(
      points.map {|lon, lat| RouteStopPattern::GEOFACTORY.point(lon, lat)}
    )
  end

  def distance_sq(p1,p2)
    (p2[0] - p1[0])**2 + (p2[1] - p1[1])**2
  end

  def distance_to_segment(t, p1, p2)
    s = distance_sq(p1, p2).to_f
    return Math.sqrt(distance_sq(p1, t)) if (s == 0)
    a = ((t[0] - p1[0])*(p2[0] - p1[0]) + (t[1] - p1[1])*(p2[1] - p1[1])).to_f / s
    return Math.sqrt(distance_sq(t, p1)) if (a < 0)
    return Math.sqrt(distance_sq(t, p2)) if (a > 1)
    x = p1[0] + a*(p2[0] - p1[0])
    y = p1[1] + a*(p2[1] - p1[1])
    Math.sqrt(distance_sq(t, [x,y]))
  end

  def nearest_segment_point(t, p1, p2)
    s = distance_sq(p1, p2).to_f
    return p1 if (s == 0)
    a = ((t[0] - p1[0])*(p2[0] - p1[0]) + (t[1] - p1[1])*(p2[1] - p1[1])).to_f / s
    return p1 if (a < 0)
    return p2 if (a > 1)
    x = p1[0] + a*(p2[0] - p1[0])
    y = p1[1] + a*(p2[1] - p1[1])
    [x, y]
  end

  def calculate_distances
    distances_map = {}
    segments = []
    self.geometry[:coordinates][1..-1].each_index {|i| segments << [self.geometry[:coordinates][i], self.geometry[:coordinates][i+1]]}
    total_distance = 0.0
    self.stop_pattern.map {|s| Stop.find_by_onestop_id!(s)}.each do |stop|
      stop_seg_distances = []
      segments.each do |s|
        stop_seg_distances << distance_to_segment(stop.geometry[:coordinates], s[0], s[1])
      end
      min_i = stop_seg_distances.index(stop_seg_distances.min)
      seg_point = nearest_segment_point(stop.geometry[:coordinates], segments[min_i][0], segments[min_i][1])
      first_cut = []
      second_cut = []
      if seg_point.eql?(segments[min_i][0])
        first_cut = segments[0...min_i]
        second_cut = segments[min_i..-1]
      elsif seg_point.eql?(segments[min_i][1])
        first_cut = segments[0..min_i]
        second_cut = segments[min_i+1..-1]
      else
        # seg point is somewhere on the segment between endpoints
        first_cut = segments[0...min_i] << [segments[min_i][0], seg_point]
        second_cut = segments[min_i+1..-1].unshift([seg_point, segments[min_i][1]])
      end

      if !first_cut.empty?
        total_distance += first_cut.map{|s| distance = Haversine.distance(s[0][1], s[0][0], s[1][1], s[1][0]).to_m }.reduce(:+)
      end
      distances_map[stop.onestop_id] = total_distance
      segments = second_cut
    end
    distances_map
  end

  def inspect_geometry(trip, stop_points)
    issues = {:empty => false}
    if trip.shape_id.nil? || self.geometry[:coordinates].empty?
      issues[:empty] = true
    else
      if Set.new(stop_points).subset?(Set.new(self.geometry[:coordinates]))
        self.is_only_stop_points = true
      end
    end
    # more inspections will go here
    issues
  end

  def tl_geometry(stop_points, issues)
    # modify rsp geometry based on issues
    if issues[:empty]
      # create a new geometry from the trip stop points
      self.geometry = RouteStopPattern.new_geometry(stop_points)
      self.is_generated = true
      self.is_modified = true
      self.is_only_stop_points = true
    end
    # more geometry modification will go here
  end

  ##### FromGTFS ####
  include FromGTFS
  def self.from_gtfs(trip, stop_pattern, shape_points)
    raise ArgumentError.new('Need at least one Stop') if stop_pattern.empty? || shape_points.empty?
    rsp = RouteStopPattern.new(
      stop_pattern: stop_pattern,
      geometry: self.new_geometry(shape_points)
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
