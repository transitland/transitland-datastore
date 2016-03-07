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
#  identifiers                        :string           default([]), is an Array
#  timezone                           :string
#  last_conflated_at                  :datetime
#
# Indexes
#
#  #c_stops_cu_in_changeset_id_index   (created_or_updated_in_changeset_id)
#  index_current_stops_on_geometry     (geometry)
#  index_current_stops_on_identifiers  (identifiers)
#  index_current_stops_on_onestop_id   (onestop_id)
#  index_current_stops_on_tags         (tags)
#  index_current_stops_on_updated_at   (updated_at)
#

class BaseStop < ActiveRecord::Base
  self.abstract_class = true

  include IsAnEntityImportedFromFeeds

  attr_accessor :served_by, :not_served_by
end

class Stop < BaseStop
  self.table_name_prefix = 'current_'

  GEOHASH_PRECISION = 10

  include HasAOnestopId
  include IsAnEntityWithIdentifiers
  include HasAGeographicGeometry
  include HasTags
  include UpdatedSince

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
      geometry_centroid[:lat],
      geometry_centroid[:lon]
    ]
  end

  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :onestop_entity,
    virtual_attributes: [
      :served_by,
      :not_served_by,
      :identified_by,
      :not_identified_by,
    ]
  })
  def self.after_create_making_history(created_model, changeset)
    OperatorRouteStopRelationship.manage_multiple(
      stop: {
        served_by: created_model.served_by || [],
        not_served_by: created_model.not_served_by || [],
        model: created_model
      },
      changeset: changeset
    )
  end
  def before_update_making_history(changeset)
    OperatorRouteStopRelationship.manage_multiple(
      stop: {
        served_by: self.served_by || [],
        not_served_by: self.not_served_by || [],
        model: self
      },
      changeset: changeset
    )
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

  # Scheduled trips
  has_many :trips_out, class_name: ScheduleStopPair, foreign_key: "origin_id"
  has_many :trips_in, class_name: ScheduleStopPair, foreign_key: "destination_id"
  has_many :stops_out, through: :trips_out, source: :destination
  has_many :stops_in, through: :trips_in, source: :origin

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
        model = OnestopId.find!(onestop_id_or_model)
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
    score_geom = 1 / (self[:geometry].distance(other[:geometry]) / 1000.0 + 1)
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
      ConflateStopsWithOsmWorker.perform_async([self.id])
    end
  end

  def self.re_conflate_with_osm(last_conflated_at=nil)
      if last_conflated_at.nil?
        max_hours = Float(Figaro.env.max_hours_since_last_conflate.presence || 84)
        last_conflated_at = max_hours.hours.ago
      end
      Stop.last_conflated_before(last_conflated_at).ids.each_slice(1000) do |slice|
        ConflateStopsWithOsmWorker.perform_async(slice)
      end
  end

  def self.conflate_with_osm(stops)
    stops.in_groups_of(TyrService::MAX_LOCATIONS_PER_REQUEST, false).each do |group|
      Stop.transaction do
        locations = group.map do |stop|
          {
            lat: stop.geometry(as: :wkt).lat,
            lon: stop.geometry(as: :wkt).lon
          }
        end
        tyr_locate_response = TyrService.locate(locations: locations)
        now = DateTime.now
        group.each_with_index do |stop, index|
          way_id = tyr_locate_response[index][:edges][0][:way_id]
          stop_tags = stop.tags.try(:clone) || {}
          if stop_tags[:osm_way_id] != way_id
            logger.info "osm_way_id changed for Stop #{stop.onestop_id}: was \"#{stop_tags[:osm_way_id]}\" now \"#{way_id}\""
          end
          stop_tags[:osm_way_id] = way_id
          stop.update(tags: stop_tags)
          stop.update(last_conflated_at: now)
        end
      end
    end
  end

  ##### FromGTFS ####
  include FromGTFS
  def self.from_gtfs(entity, attrs={})
    # GTFS Constructor
    point = Stop::GEOFACTORY.point(*entity.coordinates)
    geohash = GeohashHelpers.encode(point, precision=GEOHASH_PRECISION)
    name = [entity.stop_name, entity.id, "unknown"]
      .select(&:present?)
      .first
    onestop_id = OnestopId.handler_by_model(self).new(
      geohash: geohash,
      name: name
    )
    stop = Stop.new(
      name: name,
      onestop_id: onestop_id.to_s,
      geometry: point.to_s
    )
    # Copy over GTFS attributes to tags
    stop.tags ||= {}
    stop.tags[:wheelchair_boarding] = entity.wheelchair_boarding
    stop.tags[:stop_desc] = entity.stop_desc
    stop.tags[:stop_url] = entity.stop_url
    stop.tags[:zone_id] = entity.zone_id
    stop.timezone = entity.stop_timezone
    stop
  end

  private

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
