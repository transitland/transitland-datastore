require 'addressable/template'

module OnestopId

  COMPONENT_SEPARATOR = '-'
  GEOHASH_FILTER = /[^0123456789bcdefghjkmnpqrstuvwxyz]/
  NAME_TILDE = /[\-\:\&\@\/]/
  NAME_FILTER = /[^[:alnum:]\~\>\<]/

  class OnestopIdException < StandardError
  end

  class OnestopIdBase

    PREFIX = nil
    MODEL = nil
    NUM_COMPONENTS = 3
    MAX_LENGTH = 64
    GEOHASH_MAX_LENGTH = 10

    attr_accessor :geohash, :name

    def initialize(string: nil, geohash: nil, name: nil)
      if string.nil? && (geohash.nil? || name.nil?)
        fail ArgumentError.new('argument must be either a onestop id string or both a geohash and name.')
      end
      if string && string.length > 0
        geohash = string.split(COMPONENT_SEPARATOR)[1]
        name = string.split(COMPONENT_SEPARATOR)[2]
      else
        geohash = geohash.to_s.downcase.gsub(GEOHASH_FILTER, '')
        name = name.to_s.downcase.gsub(NAME_TILDE, '~').gsub(NAME_FILTER, '')
      end
      @geohash = geohash
      @name = name
    end

    def self.match?(value)
      if value && value.length > 0
        split = value.split(COMPONENT_SEPARATOR)
        split[0].to_sym == self::PREFIX && split.size == self::NUM_COMPONENTS
      end
    end

    def to_s
      [
        self.class::PREFIX,
        @geohash[0...self.class::GEOHASH_MAX_LENGTH],
        @name
      ].join(COMPONENT_SEPARATOR)[0...self.class::MAX_LENGTH]
    end

    def validate
      errors = []
      errors << 'invalid geohash' unless @geohash.present?
      errors << 'invalid name' unless @name.present?
      errors << 'invalid geohash' unless validate_geohash(@geohash)
      errors << 'invalid name' unless validate_name(@name)
      return (errors.size == 0), errors
    end

    def validate!
      valid, errors = self.validate
      raise OnestopIdException.new(errors.join(', ')) unless valid
    end

    def valid?
      return validate[0]
    end

    def errors
      return validate[1]
    end

    private

    def validate_geohash(value)
      !(value =~ GEOHASH_FILTER)
    end

    def validate_name(value)
      !(value =~ NAME_FILTER)
    end
  end

  class OperatorOnestopId < OnestopIdBase
    PREFIX = :o
    MODEL = Operator
  end

  class FeedOnestopId < OnestopIdBase
    PREFIX = :f
    MODEL = Feed
  end

  class GTFSRealtimeFeedOnestopId < OnestopIdBase
    NUM_COMPONENTS = 2
    PREFIX = :f
    MODEL = GTFSRealtimeFeed
    def initialize(string: nil, name: nil)
      if string && string.length > 0
        name = string.split(COMPONENT_SEPARATOR)[-1]
      end
      @name = name
    end
      
    def to_s
      [
        self.class::PREFIX,
        @name
      ].join(COMPONENT_SEPARATOR)[0...self.class::MAX_LENGTH]
    end

    def validate
      errors = []
      errors << 'invalid name' unless @name.present?
      errors << 'invalid name' unless validate_name(@name)
      return (errors.size == 0), errors
    end
  end

  class StopOnestopId < OnestopIdBase
    PREFIX = :s
    MODEL = Stop
    def self.match?(value)
      super && !value.include?('<') && !value.include?('>')
    end
  end

  class StopEgressOnestopId < OnestopIdBase
    PREFIX = :s
    MODEL = StopEgress
    def self.match?(value)
      super && value.include?('>')
    end
  end

  class StopPlatformOnestopId < OnestopIdBase
    PREFIX = :s
    MODEL = StopPlatform
    def self.match?(value)
      super && value.include?('<')
    end
  end

  class RouteOnestopId < OnestopIdBase
    PREFIX = :r
    MODEL = Route

    def to_s
      geohash = @geohash[0...self.class::GEOHASH_MAX_LENGTH]
      # Both Route and their RouteStopPatterns will share a name component whose max length
      # is dependent on the fixed length components of the RouteStopPattern onestop id (which includes the Route onestop id)
      # a variable length route geohash, and the total limitation of 64 chars for all onestop ids.
      # Route onestop ids will have 1 prefix, 2 dashes, and a variable-length route geohash up to 10 characters long.
      # RouteStopPattern onestop ids will have a route onestop id plus 2 dashes and 2 geohashes (stop pattern and geometry)
      # of 6 chars long each. The final max value of the name length is computed in RouteStopPatternOnestopId.max_name_length
      # and will be between 64 - (1 + 2 + 10 + 2 + 2*6) = 37 and 46 chars long.
      [
        self.class::PREFIX,
        geohash,
        @name[0...RouteStopPatternOnestopId.max_name_length(geohash.length)],
      ].join(COMPONENT_SEPARATOR)[0...self.class::MAX_LENGTH]
    end
  end

  class RouteStopPatternOnestopId < OnestopIdBase
    PREFIX = :r
    MODEL = RouteStopPattern
    NUM_COMPONENTS = 5
    HASH_LENGTH = 6

    attr_accessor :stop_hash, :geometry_hash

    def initialize(string: nil, route_onestop_id: nil, stop_pattern: nil, geometry_coords: nil, geohash: nil, name: nil)
      if string.nil? && (route_onestop_id.nil? || stop_pattern.nil? || geometry_coords.nil?)
        fail ArgumentError.new("argument must include a route onestop id,stop pattern array of stop onestop ids,and array of geographic coordinate arrays.")
      end
      if string && string.length > 0
        geohash = string.split(COMPONENT_SEPARATOR)[1]
        name = string.split(COMPONENT_SEPARATOR)[2]
        stop_hash = string.split(COMPONENT_SEPARATOR)[3]
        geometry_hash = string.split(COMPONENT_SEPARATOR)[4]
      else
        geohash = route_onestop_id.split(COMPONENT_SEPARATOR)[1].downcase.gsub(GEOHASH_FILTER, '')
        name = route_onestop_id.split(COMPONENT_SEPARATOR)[2].downcase.gsub(NAME_TILDE, '~').gsub(NAME_FILTER, '')
        stop_hash = RouteStopPatternOnestopId.generate_hash_from_array(stop_pattern)
        geometry_hash = RouteStopPatternOnestopId.generate_hash_from_array(geometry_coords)
      end
      @geohash = geohash
      @name = name
      @stop_hash = stop_hash
      @geometry_hash = geometry_hash
    end

    def to_s
      geohash = @geohash[0...self.class::GEOHASH_MAX_LENGTH]
      [
        self.class::PREFIX,
        geohash,
        @name[0...self.class.max_name_length(geohash.length)],
        @stop_hash,
        @geometry_hash
      ].join(COMPONENT_SEPARATOR)[0...self.class::MAX_LENGTH]
    end

    def validate
      errors = super[1]
      errors << 'invalid stop pattern hash' unless @stop_hash.present?
      errors << 'invalid stop pattern hash' unless validate_hash(@stop_hash)
      errors << 'invalid geometry hash' unless @geometry_hash.present?
      errors << 'invalid geometry hash' unless validate_hash(@geometry_hash)
      return (errors.size == 0), errors
    end

    def self.generate_hash_from_array(array)
      Digest::MD5.hexdigest(array.to_s)[0...HASH_LENGTH]
    end

    def self.route_onestop_id(onestop_id)
      onestop_id.split(COMPONENT_SEPARATOR)[0..2].join(COMPONENT_SEPARATOR)
    end

    def self.max_name_length(geohash_length)
      num_fixed_chars = NUM_COMPONENTS + 2*(HASH_LENGTH)
      MAX_LENGTH - (num_fixed_chars + geohash_length)
    end

    private

    def validate_hash(value)
      (value.is_a? String) && value.length == HASH_LENGTH
    end
  end

  LOOKUP_MODEL = Hash[OnestopId::OnestopIdBase.descendants.map { |c| [c::MODEL, c] }]

  def self.handler_by_string(string: nil)
    LOOKUP_MODEL.values.select { |cls| cls.match?(string) }.first
  end

  def self.handler_by_model(model)
    LOOKUP_MODEL[model]
  end

  def self.validate_onestop_id_string(onestop_id, expected_entity_type: nil)
    klass = handler_by_string(string: onestop_id)
    return false, ['must not be empty'] if onestop_id.blank?
    return false, ['no matching handler'] unless klass
    klass.new(string: onestop_id).validate
  end

  def self.find_current_and_old(onestop_id)
    model = handler_by_string(string: onestop_id)::MODEL
    entity = model.find_by(onestop_id: onestop_id)
    if entity.nil?
      old_entity = Object.const_get("Old#{model.name}").find_by(onestop_id: onestop_id)
      entity = old_entity.current unless old_entity.nil?
    end
    entity
  end

  def self.find_current_and_old!(onestop_id)
    model = handler_by_string(string: onestop_id)::MODEL
    begin
      model.find_by!(onestop_id: onestop_id)
    rescue ActiveRecord::RecordNotFound
      entity = Object.const_get("Old#{model.name}").find_by!(onestop_id: onestop_id)
      fail ActiveRecord::RecordNotFound, "#{model.name}: #{onestop_id} has been destroyed." if entity.current.nil?
      entity.current
    end
  end

  def self.find(onestop_id)
    handler_by_string(string: onestop_id)::MODEL.find_by(onestop_id: onestop_id)
  end

  def self.find!(onestop_id)
    handler_by_string(string: onestop_id)::MODEL.find_by!(onestop_id: onestop_id)
  end
end
