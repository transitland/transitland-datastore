class OnestopIdService
  include Singleton

  MODEL_TO_PREFIX = {
    Stop => 's',
    Operator => 'o'
  }
  PREFIX_TO_MODEL = MODEL_TO_PREFIX.invert
  COMPONENT_SEPARATOR = '-'
  GEOHASH_LENGTH = {
    Stop => 7, # 7 digit geohash will resolve to a bounding box less than
    # or equal to 153 x 153 meters (depending upon latitude).
    Operator => 2
  }
  CANONICAL_NAME_ABBREVIATION_LENGTH = 6

  def self.find!(onestop_id)
    PREFIX_TO_MODEL[onestop_id.split(COMPONENT_SEPARATOR)[0]].find_by_onestop_id!(onestop_id)
  end
end
