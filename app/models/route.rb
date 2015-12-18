# == Schema Information
#
# Table name: current_routes
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  name                               :string
#  tags                               :hstore
#  operator_id                        :integer
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#  geometry                           :geography({:srid geometry, 4326
#  identifiers                        :string           default([]), is an Array
#
# Indexes
#
#  c_route_cu_in_changeset              (created_or_updated_in_changeset_id)
#  index_current_routes_on_geometry     (geometry)
#  index_current_routes_on_identifiers  (identifiers)
#  index_current_routes_on_operator_id  (operator_id)
#  index_current_routes_on_tags         (tags)
#  index_current_routes_on_updated_at   (updated_at)
#

class BaseRoute < ActiveRecord::Base
  self.abstract_class = true

  VEHICLE_TYPES = {
    nil => nil,
    "" => nil,
    # Basic GTFS
    "0" => "Tram",
    "1" => "Metro",
    "2" => "Rail",
    "3" => "Bus",
    "4" => "Ferry",
    "5" => "Cablecar",
    "6" => "Gondola",
    "7" => "Funicular",
    # Extended vehicle types
    # https=://support.google.com/transitpartners/answer/3520902?hl=en
    "100" => "Railway Service",
    "101" => "High Speed Rail Service",
    "102" => "Long Distance Trains",
    "103" => "Inter Regional Rail Service",
    "104" => "Car Transport Rail Service",
    "105" => "Sleeper Rail Service",
    "106" => "Regional Rail Service",
    "107" => "Tourist Railway Service",
    "108" => "Rail Shuttle (Within Complex)",
    "109" => "Suburban Railway",
    "110" => "Replacement Rail Service",
    "111" => "Special Rail Service",
    "112" => "Lorry Transport Rail Service",
    "113" => "All Rail Services",
    "114" => "Cross-Country Rail Service",
    "115" => "Vehicle Transport Rail Service",
    "116" => "Rack and Pinion Railway",
    "117" => "Additional Rail Service",
    "200" => "Coach Service",
    "201" => "International Coach Service",
    "202" => "National Coach Service",
    "203" => "Shuttle Coach Service",
    "204" => "Regional Coach Service",
    "205" => "Special Coach Service",
    "206" => "Sightseeing Coach Service",
    "207" => "Tourist Coach Service",
    "208" => "Commuter Coach Service",
    "209" => "All Coach Services",
    "300" => "Suburban Railway Service",
    "400" => "Urban Railway Service",
    "401" => "Metro Service",
    "402" => "Underground Service",
    "403" => "Urban Railway Service",
    "404" => "All Urban Railway Services",
    "405" => "Monorail",
    "500" => "Metro Service",
    "600" => "Underground Service",
    "700" => "Bus Service",
    "701" => "Regional Bus Service",
    "702" => "Express Bus Service",
    "703" => "Stopping Bus Service",
    "704" => "Local Bus Service",
    "705" => "Night Bus Service",
    "706" => "Post Bus Service",
    "707" => "Special Needs Bus",
    "708" => "Mobility Bus Service",
    "709" => "Mobility Bus for Registered Disabled",
    "710" => "Sightseeing Bus",
    "711" => "Shuttle Bus",
    "712" => "School Bus",
    "713" => "School and Public Service Bus",
    "714" => "Rail Replacement Bus Service",
    "715" => "Demand and Response Bus Service",
    "716" => "All Bus Services",
    "800" => "Trolleybus Service",
    "900" => "Tram Service",
    "901" => "City Tram Service",
    "902" => "Local Tram Service",
    "903" => "Regional Tram Service",
    "904" => "Sightseeing Tram Service",
    "905" => "Shuttle Tram Service",
    "906" => "All Tram Services",
    "1000" => "Water Transport Service",
    "1001" => "International Car Ferry Service",
    "1002" => "National Car Ferry Service",
    "1003" => "Regional Car Ferry Service",
    "1004" => "Local Car Ferry Service",
    "1005" => "International Passenger Ferry Service",
    "1006" => "National Passenger Ferry Service",
    "1007" => "Regional Passenger Ferry Service",
    "1008" => "Local Passenger Ferry Service",
    "1009" => "Post Boat Service",
    "1010" => "Train Ferry Service",
    "1011" => "Road-Link Ferry Service",
    "1012" => "Airport-Link Ferry Service",
    "1013" => "Car High-Speed Ferry Service",
    "1014" => "Passenger High-Speed Ferry Service",
    "1015" => "Sightseeing Boat Service",
    "1016" => "School Boat",
    "1017" => "Cable-Drawn Boat Service",
    "1018" => "River Bus Service",
    "1019" => "Scheduled Ferry Service",
    "1020" => "Shuttle Ferry Service",
    "1021" => "All Water Transport Services",
    "1100" => "Air Service",
    "1101" => "International Air Service",
    "1102" => "Domestic Air Service",
    "1103" => "Intercontinental Air Service",
    "1104" => "Domestic Scheduled Air Service",
    "1105" => "Shuttle Air Service",
    "1106" => "Intercontinental Charter Air Service",
    "1107" => "International Charter Air Service",
    "1108" => "Round-Trip Charter Air Service",
    "1109" => "Sightseeing Air Service",
    "1110" => "Helicopter Air Service",
    "1111" => "Domestic Charter Air Service",
    "1112" => "Schengen-Area Air Service",
    "1113" => "Airship Service",
    "1114" => "All Air Services",
    "1200" => "Ferry Service",
    "1300" => "Telecabin Service",
    "1301" => "Telecabin Service",
    "1302" => "Cable Car Service",
    "1303" => "Elevator Service",
    "1304" => "Chair Lift Service",
    "1305" => "Drag Lift Service",
    "1306" => "Small Telecabin Service",
    "1307" => "All Telecabin Services",
    "1400" => "Funicular Service",
    "1401" => "Funicular Service",
    "1402" => "All Funicular Service",
    "1500" => "Taxi Service",
    "1501" => "Communal Taxi Service",
    "1502" => "Water Taxi Service",
    "1503" => "Rail Taxi Service",
    "1504" => "Bike Taxi Service",
    "1505" => "Licensed Taxi Service",
    "1506" => "Private Hire Service Vehicle",
    "1507" => "All Taxi Services",
    "1600" => "Self Drive",
    "1601" => "Hire Car",
    "1602" => "Hire Van",
    "1603" => "Hire Motorbike",
    "1604" => "Hire Cycle",
    "1700" => "Miscellaneous Service",
    "1701" => "Cable Car",
    "1702" => "Horse-drawn Carriage"
  }

  include IsAnEntityImportedFromFeeds

  attr_accessor :serves, :does_not_serve, :operated_by
end

class Route < BaseRoute
  self.table_name_prefix = 'current_'

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
      'Operated by (name)',
      'Operated by (Onestop ID)'
    ]
  end

  def csv_row_values
    [
      onestop_id,
      name,
      operator.try(:name),
      operator.try(:onestop_id)
    ]
  end

  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :onestop_entity,
    virtual_attributes: [
      :serves,
      :does_not_serve,
      :operated_by,
      :identified_by,
      :not_identified_by,
      :imported_from_feed
    ]
  })

  # FIXME: this is a temporary fix to run both the following `before_create_making_history` changeset
  # callback as well as the callback of the same name that is included from IsAnEntityWithIdentifiers
  class << Route
    alias_method :existing_before_create_making_history, :before_create_making_history
  end
  def self.before_create_making_history(new_model, changeset)
    operator = Operator.find_by_onestop_id!(new_model.operated_by)
    new_model.operator = operator
    self.existing_before_create_making_history(new_model, changeset)
  end
  def self.after_create_making_history(created_model, changeset)
    OperatorRouteStopRelationship.manage_multiple(
      route: {
        serves: created_model.serves || [],
        does_not_serve: created_model.does_not_serve || [],
        model: created_model
      },
      changeset: changeset
    )
  end
  def before_update_making_history(changeset)
    if self.operated_by.present?
      operator = Operator.find_by_onestop_id!(self.operated_by)
      self.operator = operator
    end
    OperatorRouteStopRelationship.manage_multiple(
      route: {
        serves: self.serves || [],
        does_not_serve: self.does_not_serve || [],
        model: self
      },
      changeset: changeset
    )
    super(changeset)
  end
  def before_destroy_making_history(changeset, old_model)
    routes_serving_stop.each do |route_serving_stop|
      route_serving_stop.destroy_making_history(changeset: changeset)
    end
    return true
  end

  has_many :routes_serving_stop
  has_many :stops, through: :routes_serving_stop
  has_many :schedule_stop_pairs
  belongs_to :operator

  validates :name, presence: true

  scope :operated_by, -> (model_or_onestop_id) {
    if model_or_onestop_id.is_a?(Operator)
      where(operator: model_or_onestop_id)
    elsif model_or_onestop_id.is_a?(String)
      operator = Operator.find_by_onestop_id!(model_or_onestop_id)
      where(operator: operator)
    else
      raise ArgumentError.new('must provide an Operator model or a Onestop ID')
    end
  }

  scope :stop_within_bbox, -> (bbox) {
    where(id: RouteServingStop.select(:route_id).where(stop: Stop.geometry_within_bbox(bbox)))
  }

  ##### FromGTFS ####
  include FromGTFS
  def self.from_gtfs(entity, stops)
    # GTFS Constructor
    raise ArgumentError.new('Need at least one Stop') if stops.empty?
    geohash = GeohashHelpers.fit(stops.map { |i| i[:geometry] })
    name = [entity.route_short_name, entity.route_long_name, entity.id, "unknown"]
      .select(&:present?)
      .first
    onestop_id = OnestopId.new(
      entity_prefix: 'r',
      geohash: geohash,
      name: name
    )
    route = Route.new(
      name: name,
      onestop_id: onestop_id.to_s,
      # geometry:
    )
    # Copy over GTFS attributes to tags
    route.tags ||= {}
    route.tags[:vehicle_type] = VEHICLE_TYPES[entity.route_type]
    route.tags[:route_long_name] = entity.route_long_name
    route.tags[:route_desc] = entity.route_desc
    route.tags[:route_url] = entity.route_url
    route.tags[:route_color] = entity.route_color
    route.tags[:route_text_color] = entity.route_text_color
    route
  end

end

class OldRoute < BaseRoute
  include OldTrackedByChangeset
  include HasAGeographicGeometry

  has_many :old_routes_serving_stop
  has_many :routes, through: :old_routes_serving_stop, source_type: 'Route'
end
