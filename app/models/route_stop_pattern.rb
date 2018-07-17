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
#  index_current_route_stop_patterns_on_stop_pattern  (stop_pattern) USING gin
#

class BaseRouteStopPattern < ActiveRecord::Base
  self.abstract_class = true

  attr_accessor :traversed_by
  attr_accessor :serves
end

class RouteStopPattern < BaseRouteStopPattern
  self.table_name_prefix = 'current_'

  COORDINATE_PRECISION = 5

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

  scope :with_trips, -> (search_string) { where_imported_with_gtfs_id(search_string) }
  scope :with_all_stops, -> (search_string) { where{stop_pattern.within(search_string)} }
  scope :with_any_stops, -> (stop_onestop_ids) { where( "stop_pattern && ARRAY[?]::varchar[]", stop_onestop_ids ) }

  def trips
    entities_imported_from_feed.map(&:gtfs_id).uniq.compact
  end

  def ordered_ssp_trip_chunks(&block)
    if block
      ScheduleStopPair.where(route_stop_pattern: self).order(:trip, :origin_departure_time).slice_when { |s1, s2|
        !s1.trip.eql?(s2.trip)
      }.each {|trip_chunk| yield trip_chunk }
    end
  end

  ##### FromGTFS ####
  def generate_onestop_id
    route = self.traversed_by.present? ? self.traversed_by : self.route
    stop_pattern = self.serves.present? ? self.serves.map(&:onestop_id) : self.stop_pattern
    fail Exception.new('route required') unless route
    fail Exception.new('stop_pattern required') unless stop_pattern
    fail Exception.new('geometry required') unless self.geometry
    onestop_id = OnestopId.handler_by_model(RouteStopPattern).new(
     route_onestop_id: route.onestop_id,
     stop_pattern: stop_pattern,
     geometry_coords: self.geometry[:coordinates]
    )
    onestop_id.to_s
  end

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
      rsp.geometry = Geometry::LineString.line_string(Geometry::Lib.set_precision(shape_points, COORDINATE_PRECISION))
      rsp.geometry_source = Geometry::GTFSShapeDistanceTraveled.validate_shape_dist_traveled(stop_times, shape_points.shape_dist_traveled) ? :shapes_txt_with_dist_traveled : :shapes_txt
    else
      rsp.geometry = Geometry::LineString.line_string(Geometry::Lib.set_precision(trip_stop_points, COORDINATE_PRECISION))
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
