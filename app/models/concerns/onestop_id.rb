module OnestopId
  extend ActiveSupport::Concern

  ONESTOP_ID_PREFIX = 's'
  ONESTOP_ID_COMPONENT_SEPARATOR = '-'
  CANONICAL_NAME_ABBREVIATION_LENGTH = 6

  included do
    validates :onestop_id, presence: true, uniqueness: true
    validate :onestop_id, :validate_onestop_id
  end

  private

  def validate_onestop_id
    is_a_valid_onestop_id = true
    if !onestop_id.start_with?(ONESTOP_ID_PREFIX + ONESTOP_ID_COMPONENT_SEPARATOR)
      errors.add(:onestop_id, "must start with \"#{ONESTOP_ID_PREFIX + ONESTOP_ID_COMPONENT_SEPARATOR}\" as its 1st component")
      is_a_valid_onestop_id = false
    end
    if onestop_id.split('-').length != 3
      errors.add(:onestop_id, 'must include 3 components separated by hyphens ("-")')
      is_a_valid_onestop_id = false
    end
    if onestop_id.split('-').second.length == 0 || !!(onestop_id.split('-').second =~ /[^a-z\d]/)
      errors.add(:onestop_id, 'must include a valid geohash as its 2nd component, after "s-"')
      is_a_valid_onestop_id = false
    end
    if !!(onestop_id.split('-').third =~ /[^a-zA-Z\d]/)
      errors.add(:onestop_id, 'must include only letters and digits in its abbreviated name (the 3rd component)')
      is_a_valid_onestop_id = false
    end
    is_a_valid_onestop_id
  end

  def geohash
    # 7 digit geohash will resolve to a bounding box less than
    # or equal to 153 x 153 meters (depending upon latitude).
    # To plot a geohash: http://www.movable-type.co.uk/scripts/geohash.html
    if geometry.respond_to?(:lat) && geometry.respond_to?(:lon)
      lat = geometry.lat
      lon = geometry.lon
    elsif geometry.respond_to?(:centroid)
      centroid = geometry.centroid
      lat = centroid.lat
      lon = centroid.lon
    else
      raise ArgumentError.new "Stop doesn't have a latitude, longitude, or centroid."
    end
    GeoHash.encode(lat, lon, 7)
  end

  def generate_onestop_id(name_abbreviation_length)
    ONESTOP_ID_PREFIX + ONESTOP_ID_COMPONENT_SEPARATOR + geohash + ONESTOP_ID_COMPONENT_SEPARATOR + AbbreviateStopName.new(self.name).abbreviate(name_abbreviation_length)
  end

  def generate_unique_onestop_id
    potential_onestop_id = generate_onestop_id(CANONICAL_NAME_ABBREVIATION_LENGTH)
    i = 1
    until Stop.where(onestop_id: potential_onestop_id).count == 0
      i += 1
      if (2..3).include?(i)
        potential_onestop_id = generate_onestop_id(CANONICAL_NAME_ABBREVIATION_LENGTH + i - 1)
      else
        potential_onestop_id = "#{potential_onestop_id}#{i}"
      end
    end
    potential_onestop_id
  end
end
