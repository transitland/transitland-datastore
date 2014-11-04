# == Schema Information
#
# Table name: stops
#
#  id         :integer          not null, primary key
#  onestop_id :string(255)
#  geometry   :spatial          geometry, 4326
#  tags       :hstore
#  created_at :datetime
#  updated_at :datetime
#  name       :string(255)
#
# Indexes
#
#  index_stops_on_onestop_id  (onestop_id)
#

class Stop < ActiveRecord::Base
  has_many :stop_identifiers, dependent: :destroy

  validates :onestop_id, presence: true, uniqueness: true # TODO: make this a more meaningful validation

  PER_PAGE = 50

  GEOFACTORY = RGeo::Geographic.spherical_factory(srid: 4326) # TODO: double check this
  set_rgeo_factory_for_column :geometry, GEOFACTORY.projection_factory

  def self.match_against_existing_stop_or_create(attrs)
    if attrs.has_key?(:onestop_id) && attrs[:onestop_id].present?
      # TODO: update?
      return Stop.find_or_initialize_by(onestop_id: attrs[:onestop_id])
    end
    radius = 10 # TODO: move to config
    existing_stops = Stop.select{['stops.*', st_distance(geometry, attrs[:geometry]).as(distance)]}.where{st_dwithin(stops.geometry, attrs[:geometry], radius) & (name == attrs[:name]) }.order('distance')
    if existing_stops.count == 0
      return Stop.create(attrs)
    else
      # TODO: update attributes
      return existing_stops.first
    end
  end

  before_validation :set_onestop_id

  def set_onestop_id
    self.onestop_id ||= self.generate_unique_onestop_id({})
  end

  def generate_unique_onestop_id(options)
    # TODO: replace this holder version with something real
    # with the form of AGENCY-STOPNAME
    potential_onestop_id = name.gsub(' ', '-').gsub(/[\.\#]/, '')[0..10].downcase
    if options.has_key?(:trailing_num) && options[:trailing_num] > 0
      trailing_num = options[:trailing_num]
      potential_onestop_id = "#{potential_onestop_id}-#{options[:trailing_num]}"
    end
    trailing_num ||= 1
    if Stop.where(onestop_id: potential_onestop_id).count > 0 # TODO: make this more efficient; cache the list?
      generate_unique_onestop_id({ trailing_num: trailing_num + 1 })
    else
      potential_onestop_id
    end
  end
end
