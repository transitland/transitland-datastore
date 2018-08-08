# == Schema Information
#
# Table name: current_stops
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  geometry                           :geography({:srid geometry, 4326
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  name                               :string
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  timezone                           :string
#  last_conflated_at                  :datetime
#  type                               :string
#  parent_stop_id                     :integer
#  osm_way_id                         :integer
#  edited_attributes                  :string           default([]), is an Array
#  wheelchair_boarding                :boolean
#  directionality                     :integer
#  geometry_reversegeo                :geography({:srid point, 4326
#
# Indexes
#
#  #c_stops_cu_in_changeset_id_index           (created_or_updated_in_changeset_id)
#  index_current_stops_on_geometry             (geometry) USING gist
#  index_current_stops_on_geometry_reversegeo  (geometry_reversegeo) USING gist
#  index_current_stops_on_onestop_id           (onestop_id) UNIQUE
#  index_current_stops_on_parent_stop_id       (parent_stop_id)
#  index_current_stops_on_tags                 (tags)
#  index_current_stops_on_updated_at           (updated_at)
#  index_current_stops_on_wheelchair_boarding  (wheelchair_boarding)
#

class BaseStop < ActiveRecord::Base
  self.abstract_class = true
end

class Stop < BaseStop
  self.table_name = 'current_stops'
  attr_accessor :parent_stop_onestop_id
  attr_accessor :served_by, :not_served_by
  attr_accessor :includes_stop_transfers, :does_not_include_stop_transfers
  validates :timezone, presence: true

  include HasAOnestopId
  include HasAGeographicGeometry
  include HasTags
  include UpdatedSince
  include IsAnEntityImportedFromFeeds
  include IsAnEntityWithIssues
  extend Enumerize
  enumerize :directionality, in: {:enter => 1, :exit => 2, :both => 0}
  # TODO: use default: :both ?

  include CanBeSerializedToCsv
  def self.csv_column_names
    [
      'Onestop ID',
      'Name',
      'Operators serving stop (names)',
      'Operators serving stop (Onestop IDs)',
      'Latitude (centroid)',
      'Longitude (centroid)'
    ]
  end
  def csv_row_values
    [
      onestop_id,
      name,
      operators_serving_stop.map {|oss| oss.operator.name }.join(', '),
      operators_serving_stop.map {|oss| oss.operator.onestop_id }.join(', '),
      geometry_centroid.lat,
      geometry_centroid.lon
    ]
  end


  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :onestop_entity,
    virtual_attributes: [
      :served_by,
      :not_served_by,
      :includes_stop_transfers,
      :does_not_include_stop_transfers,
      :add_imported_from_feeds,
      :not_imported_from_feeds
    ],
    protected_attributes: [
      :last_conflated_at,
      :type
    ],
    sticky_attributes: [
      :name,
      :geometry,
      :wheelchair_boarding
    ]
  })


  def update_parent_stop(changeset)
    if self.parent_stop_onestop_id
      parent_stop = Stop.find_by_onestop_id!(self.parent_stop_onestop_id)
      self.update!(parent_stop: parent_stop)
    end
  end

  def update_stop_pattern_onestop_ids(old_onestop_ids, changeset)
    old_onestop_ids = Array.wrap(old_onestop_ids)
    RouteStopPattern.with_any_stops(old_onestop_ids).each do |rsp|
      rsp.stop_pattern.map! { |stop_onestop_id| old_onestop_ids.include?(stop_onestop_id) ? self.onestop_id : stop_onestop_id }
      rsp.update_making_history(changeset: changeset)
    end
  end

  def after_change_onestop_id(old_onestop_id, changeset)
    self.update_stop_pattern_onestop_ids(old_onestop_id, changeset)
  end

  def after_merge_onestop_ids(merging_onestop_ids, changeset)
    self.update_stop_pattern_onestop_ids(merging_onestop_ids, changeset)
  end

  def update_associations(changeset)
    update_parent_stop(changeset)
    update_entity_imported_from_feeds(changeset)
    update_served_by(changeset)
    update_includes_stop_transfers(changeset)
    update_does_not_include_stop_transfers(changeset)
    super(changeset)
  end

  def before_destroy_making_history(changeset, old_model)
    operators_serving_stop.each do |operator_serving_stop|
      operator_serving_stop.destroy_making_history(changeset: changeset)
    end
    routes_serving_stop.each do |route_serving_stop|
      route_serving_stop.destroy_making_history(changeset: changeset)
    end
    return true
  end

  # Operators serving this stop
  has_many :operators_serving_stop
  has_many :operators, through: :operators_serving_stop

  # Routes serving this stop
  has_many :routes_serving_stop
  has_many :routes, through: :routes_serving_stop

  def operators_serving_stop_and_platforms
    OperatorServingStop
      .where('stop_id IN (?) OR stop_id = ?', Stop.where(parent_stop_id: self.id).select(:id), self.id)
      .select('DISTINCT ON (current_operators_serving_stop.operator_id) *')
  end

  def routes_serving_stop_and_platforms
    RouteServingStop
      .where('stop_id IN (?) OR stop_id = ?', Stop.where(parent_stop_id: self.id).select(:id), self.id)
      .select('DISTINCT ON (current_routes_serving_stop.route_id) *')
  end

  def vehicle_types_serving_stop_and_platforms
    # Use cacheable relations
    (self.stop_platforms + [self]).map { |s| s.served_by_vehicle_types }.flatten.uniq
  end

  # Route vehicle_type serving stop
  def served_by_vehicle_types
    self.routes_serving_stop.map(&:route).map(&:vehicle_type).uniq
  end

  scope :served_by_vehicle_types, -> (vehicle_types) {
    vehicle_types = Array.wrap(vehicle_types).map { |vt| GTFS::Route.match_vehicle_type(vt).to_s.to_i }
    joins{routes_serving_stop.route}
      .where({current_routes: {vehicle_type: vehicle_types}})
      .distinct
  }

  # GTFS
  has_many :gtfs_entities, class_name: GTFSStop, foreign_key: :entity_id

  # Station Hierarchy
  has_many :stop_egresses, class_name: 'StopEgress', foreign_key: :parent_stop_id
  has_many :stop_platforms, class_name: 'StopPlatform', foreign_key: :parent_stop_id

  # Internal connectivity
  has_many :stop_transfers

  # Scheduled trips
  has_many :trips_out, class_name: ScheduleStopPair, foreign_key: "origin_id"
  has_many :trips_in, class_name: ScheduleStopPair, foreign_key: "destination_id"
  has_many :stops_out, through: :trips_out, source: :destination
  has_many :stops_in, through: :trips_in, source: :origin

  # Issues
  has_many :issues, through: :entities_with_issues

  belongs_to :parent_stop, class_name: 'Stop'

  # Add service from an Operator or Route
  scope :served_by, -> (onestop_ids_and_models) {
    operators = []
    routes = []
    onestop_ids_and_models.each do |onestop_id_or_model|
      case onestop_id_or_model
      when Operator
        operators << onestop_id_or_model
      when Route
        routes << onestop_id_or_model
      when String
        model = OnestopId.find_current_and_old!(onestop_id_or_model)
        case model
        when Route then routes << model
        when Operator then operators << model
        else ArgumentError.new('only accepts Operator or Route models')
        end
      else
        raise ArgumentError.new('must provide an Operator model or a Onestop ID')
      end
    end
    if operators.length > 0 && routes.length > 0
      joins{
        operators_serving_stop.operator
      }.joins{
        routes_serving_stop.route
      }.where{
        (operators_serving_stop.operator_id >> operators.map(&:id)) |
        (routes_serving_stop.route_id >> routes.map(&:id))
      }.uniq(:stop)
    elsif operators.length > 0
      joins{operators_serving_stop.operator}.where{operators_serving_stop.operator_id >> operators.map(&:id)}.uniq(:stop)
    elsif routes.length > 0
      joins{routes_serving_stop.route}.where{routes_serving_stop.route_id >> routes.map(&:id)}.uniq(:stop)
    else
      raise ArgumentError.new('must provide at least one Operator or Route')
    end
  }
  scope :served_by_route, -> (route) {
    joins{routes_serving_stop.route}.where{routes_serving_stop.route_id == route.id}
  }
  scope :served_by_operator, -> (operator) {
    joins{operators_serving_stop.operator}.where{operators_serving_stop.operator_id == operator.id}
  }

  # Last conflated before
  scope :last_conflated_before, -> (last_conflated_at) {
    where('last_conflated_at <= ?', last_conflated_at)
  }

  scope :with_min_platforms, -> (min_count) {
    where(type: nil)
    .joins("INNER JOIN current_stops AS current_stop_platforms ON current_stop_platforms.type = 'StopPlatform' AND current_stop_platforms.parent_stop_id = current_stops.id")
    .group('current_stops.id, current_stop_platforms.parent_stop_id')
    .having('COUNT(current_stop_platforms.id) >= ?', min_count || 1)
  }

  scope :with_min_egresses, -> (min_count) {
    where(type: nil)
    .joins("INNER JOIN current_stops AS current_stop_egresses ON current_stop_egresses.type = 'StopEgress' AND current_stop_egresses.parent_stop_id = current_stops.id")
    .group('current_stops.id, current_stop_egresses.parent_stop_id')
    .having('COUNT(current_stop_egresses.id) >= ?', min_count || 1)
  }


  def geometry_reversegeo=(value)
    super(geometry_parse(value))
  end

  def geometry_reversegeo(**kwargs)
    geometry_encode(self.send(:read_attribute, :geometry_reversegeo), **kwargs)
  end

  def geometry_for_centroid
    read_attribute(:geometry_reversegeo) || read_attribute(:geometry)
  end

  def coordinates
    g = geometry_centroid
    [g.lon, g.lat]
  end

  # Similarity search
  def self.find_by_similarity(point, name, radius=100, threshold=0.75)
    # Similarity search. Returns a score,stop tuple or nil.
    other = Stop.new(name: name, geometry: point.to_s)
    # Class method, like other find_by methods.
    where { st_dwithin(geometry, point, radius)
    }.map { |stop|  [stop, stop.similarity(other)]
    }.select { |stop, score|  score >= threshold
    }.sort_by { |stop, score| score
    }.last
  end

  def similarity(other)
    # TODO: instance method, compare against a second instance?
    # Inverse distance in km
    score_geom = 1 / (self.geometry_centroid.distance(other.geometry_centroid) / 1000.0 + 1)
    # Levenshtein distance as ratio of name length
    score_text = 1 - (Text::Levenshtein.distance(self.name, other.name) / [self.name.size, other.name.size].max.to_f)
    # Weighted average
    (score_geom * 0.5) + (score_text * 0.5)
  end

  # Before save
  before_save :clean_attributes

  # Conflate with OSM
  if Figaro.env.auto_conflate_stops_with_osm.present? &&
     Figaro.env.auto_conflate_stops_with_osm == 'true'
    after_save :queue_conflate_with_osm
  end

  def queue_conflate_with_osm
    if self.geometry_changed? && ActiveRecord::Base.connection.open_transactions == 0
      # Don't conflate if we're in a database transaction--the async
      # worker wont' be able to find the stop in the database yet.
      # For stops created by changesets, see the end of the
      # Changeset.apply! method (app/model/changeset.rb:122)
      StopConflateWorker.perform_async([self.id])
    end
  end

  def self.re_conflate_with_osm(last_conflated_at=nil)
      if last_conflated_at.nil?
        max_hours = Float(Figaro.env.max_hours_since_last_conflate.presence || 84)
        last_conflated_at = max_hours.hours.ago
      end
      Stop.last_conflated_before(last_conflated_at).ids.each_slice(1000) do |slice|
        StopConflateWorker.perform_async(slice)
      end
  end

  def self.conflate_with_osm(stops)
    stops.in_groups_of(TyrService::MAX_LOCATIONS_PER_REQUEST, false).each do |group|
      Stop.transaction do
        locations = group.map do |stop|
          geom = stop.geometry_for_centroid
          {
            lat: geom.lat,
            lon: geom.lon
          }
        end
        tyr_locate_response = TyrService.locate(locations: locations)
        now = DateTime.now
        group.each_with_index do |stop, index|
          osm_way_id = stop.osm_way_id

          if tyr_locate_response[index].nil?
            log "Index #{index} for stop #{stop.onestop_id} not found in Tyr Response."
            next
          end

          # Issues will disappear on their own when a way id is finally found (e.g. the stop location is fixed)
          # An issue will be replaced when conflation occurs again and the missing way id persists
          Issue.issues_of_entity(stop, entity_attributes: ["osm_way_id"]).each(&:deprecate)
          if tyr_locate_response[index][:edges].present?
            osm_way_id = tyr_locate_response[index][:edges][0][:way_id]
          else
            log "Tyr response for Stop #{stop.onestop_id} did not contain edges. Leaving osm_way_id."
            Issue.create!(issue_type: 'missing_stop_conflation_result', details: "Tyr response for Stop #{stop.onestop_id} did not contain edges. Leaving osm_way_id.")
              .entities_with_issues.create!(entity: stop, entity_attribute: 'osm_way_id')
          end

          if stop.osm_way_id != osm_way_id
            log "osm_way_id changed for Stop #{stop.onestop_id}: was \"#{stop.osm_way_id}\" now \"#{osm_way_id}\""
          end
          # Copy osm_way_id as a tag for now
          stop_tags = stop.tags.try(:clone) || {}
          stop_tags[:osm_way_id] = osm_way_id
          # Update stop
          stop.update(
            osm_way_id: osm_way_id,
            tags: stop_tags,
            last_conflated_at: now
          )
        end
      end
    end
  end

  def generate_onestop_id
    fail Exception.new('geometry required') if geometry.nil?
    fail Exception.new('name required') if name.nil?
    geohash = GeohashHelpers.encode(self.geometry_centroid)
    name = self.name.gsub(/[\>\<]/, '')
    onestop_id = OnestopId.handler_by_model(self.class).new(
      geohash: geohash,
      name: name
    )
    onestop_id.validate!
    onestop_id.to_s
  end

  private

  def update_includes_stop_transfers(changeset)
    (self.includes_stop_transfers || []).each do |stop_transfer|
      to_stop = Stop.find_by_onestop_id!(stop_transfer[:to_stop_onestop_id])
      existing_relationship = StopTransfer.find_by(
        stop: self,
        to_stop: to_stop
      )
      new_attrs = {
        stop: self,
        to_stop: to_stop,
        transfer_type: stop_transfer[:transfer_type],
        min_transfer_time: stop_transfer[:min_transfer_time]
      }
      if existing_relationship
        existing_relationship.update_making_history(
          changeset: changeset,
          new_attrs: new_attrs
        )
      else
        StopTransfer.create_making_history(
          changeset: changeset,
          new_attrs: new_attrs
        )
      end
    end
  end

  def update_does_not_include_stop_transfers(changeset)
    (self.does_not_include_stop_transfers || []).each do |stop_transfer|
      existing_relationship = StopTransfer.find_by(
        stop: self,
        to_stop: Stop.find_by_onestop_id!(stop_transfer[:to_stop_onestop_id])
      )
      if existing_relationship
        existing_relationship.destroy_making_history(changeset: changeset)
      end
    end
  end

  def update_served_by(changeset)
    OperatorRouteStopRelationship.manage_multiple(
      stop: {
        served_by: self.served_by || [],
        not_served_by: self.not_served_by || [],
        model: self
      },
      changeset: changeset
    )
  end

  def clean_attributes
    self.name.strip! if self.name.present?
  end
end

class OldStop < BaseStop
  include OldTrackedByChangeset
  include HasAGeographicGeometry
  has_many :old_operators_serving_stop, as: :stop
  has_many :operators, through: :old_operators_serving_stop, source_type: 'Stop'
  has_many :old_routes_serving_stop, as: :stop
  has_many :routes, through: :old_routes_serving_stop, source_type: 'Stop'
end
