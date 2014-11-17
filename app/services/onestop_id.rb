class OnestopId
  ONESTOP_ID_PREFIX = 's'
  ONESTOP_ID_COMPONENT_SEPARATOR = '-'
  CANONICAL_NAME_ABBREVIATION_LENGTH = 6

  attr_accessor :name, :geometry

  def initialize(name, geometry)
    @name = name
    if (geometry.respond_to?(:lat) && geometry.respond_to?(:lon)) || geometry.respond_to?(:centroid)
      @geometry = geometry
    elsif geometry.is_a? String
      begin
        @geometry = Stop::GEOFACTORY.parse_wkt(geometry)
      rescue RGeo::Error::ParseError
        raise ArgumentError.new "Geometry isn't a valid WKT string."
      end
    else
      raise ArgumentError.new "Geometry must either be an RGeo object or a WKT string."
    end
  end

  def self.valid?(onestop_id)
    is_a_valid_onestop_id = true
    errors = []
    if !onestop_id.start_with?(ONESTOP_ID_PREFIX + ONESTOP_ID_COMPONENT_SEPARATOR)
      errors << "must start with \"#{ONESTOP_ID_PREFIX + ONESTOP_ID_COMPONENT_SEPARATOR}\" as its 1st component"
      is_a_valid_onestop_id = false
    end
    if onestop_id.split('-').length != 3
      errors << 'must include 3 components separated by hyphens ("-")'
      is_a_valid_onestop_id = false
    end
    if onestop_id.split('-').second.length == 0 || !!(onestop_id.split('-').second =~ /[^a-z\d]/)
      errors << 'must include a valid geohash as its 2nd component, after "s-"'
      is_a_valid_onestop_id = false
    end
    if !!(onestop_id.split('-').third =~ /[^a-zA-Z\d]/)
      errors << 'must include only letters and digits in its abbreviated name (the 3rd component)'
      is_a_valid_onestop_id = false
    end
    return is_a_valid_onestop_id, errors
  end

  def generate_unique
    potential_onestop_id = generate(CANONICAL_NAME_ABBREVIATION_LENGTH)
    i = 1
    until Stop.where(onestop_id: potential_onestop_id).count == 0
      i += 1
      if (2..3).include?(i)
        potential_onestop_id = generate(CANONICAL_NAME_ABBREVIATION_LENGTH + i - 1)
      else
        potential_onestop_id = "#{potential_onestop_id}#{i}"
      end
    end
    potential_onestop_id
  end

  private

  def generate(name_abbreviation_length)
    ONESTOP_ID_PREFIX + ONESTOP_ID_COMPONENT_SEPARATOR + geohash + ONESTOP_ID_COMPONENT_SEPARATOR + AbbreviateStopName.new(@name).abbreviate(name_abbreviation_length)
  end

  def geohash
    # 7 digit geohash will resolve to a bounding box less than
    # or equal to 153 x 153 meters (depending upon latitude).
    # To plot a geohash: http://www.movable-type.co.uk/scripts/geohash.html
    if @geometry.respond_to?(:lat) && @geometry.respond_to?(:lon)
      lat = @geometry.lat
      lon = @geometry.lon
    elsif @geometry.respond_to?(:centroid)
      centroid = @geometry.centroid
      lat = centroid.lat
      lon = centroid.lon
    else
      raise ArgumentError.new "Stop doesn't have a latitude, longitude, or centroid."
    end
    GeoHash.encode(lat, lon, 7)
  end

end
