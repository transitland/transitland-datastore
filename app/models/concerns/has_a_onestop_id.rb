module HasAOnestopId
  extend ActiveSupport::Concern

  included do
    validates :onestop_id, presence: true, uniqueness: true
    validate :onestop_id, :validate_onestop_id

    before_validation :set_onestop_id

    def find_by_onestop_id!(onestop_id)
      # TODO: make this case insensitive
      self.find_by!(onestop_id: onestop_id)
    end
  end

  private

  def set_onestop_id
    self.onestop_id ||= generate_unique_onestop_id
  end

  def onestop_id_prefix_for_this_object
    OnestopIdService::MODEL_TO_PREFIX[self.class]
  end

  def validate_onestop_id
    is_a_valid_onestop_id = true
    if !onestop_id.start_with?(onestop_id_prefix_for_this_object + OnestopIdService::COMPONENT_SEPARATOR)
      errors.add(:onestop_id, "must start with \"#{onestop_id_prefix_for_this_object + OnestopIdService::COMPONENT_SEPARATOR}\" as its 1st component")
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
    # To plot a geohash: http://www.movable-type.co.uk/scripts/geohash.html
    if geometry.respond_to?(:lat) && geometry.respond_to?(:lon)
      lat = geometry.lat
      lon = geometry.lon
    elsif geometry.respond_to?(:centroid)
      centroid = geometry.centroid
      lat = centroid.lat
      lon = centroid.lon
    else
      raise ArgumentError.new "#{self.class.to_s} doesn't have a latitude, longitude, or centroid."
    end
    # TODO: also compute from a bounding box? (for an Operator)
    # https://github.com/davidmoten/geo/blob/59d0b214d32dc8563bf0339cf07d50b23b6ce8de/src/main/java/com/github/davidmoten/geo/GeoHash.java#L574
    GeoHash.encode(lat, lon, OnestopIdService::GEOHASH_LENGTH[self.class])
  end

  def generate_onestop_id(name_abbreviation_length)
    onestop_id_prefix_for_this_object + OnestopIdService::COMPONENT_SEPARATOR + geohash + OnestopIdService::COMPONENT_SEPARATOR + AbbreviateName.new(self.name).abbreviate(name_abbreviation_length)
  end

  def generate_unique_onestop_id
    potential_onestop_id = generate_onestop_id(OnestopIdService::CANONICAL_NAME_ABBREVIATION_LENGTH)
    i = 1
    until self.class.where(onestop_id: potential_onestop_id).count == 0
      i += 1
      if (2..3).include?(i)
        potential_onestop_id = generate_onestop_id(OnestopIdService::CANONICAL_NAME_ABBREVIATION_LENGTH + i - 1)
      else
        potential_onestop_id = "#{potential_onestop_id}#{i}"
      end
    end
    potential_onestop_id
  end
end
