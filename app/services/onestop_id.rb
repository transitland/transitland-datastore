require 'addressable/template'

module OnestopId

  COMPONENT_SEPARATOR = '-'
  GEOHASH_FILTER = /[^0123456789bcdefghjkmnpqrstuvwxyz]/
  NAME_TILDE = /[\-\:\&\@\/]/
  NAME_FILTER = /[^a-zA-Z\d\@\~\>\<]/
  IDENTIFIER_TEMPLATE = Addressable::Template.new("gtfs://{feed_onestop_id}/{entity_prefix}/{entity_id}")

  class OnestopIdBase

    PREFIX = nil
    MODEL = nil
    NUM_COMPONENTS = 3

    attr_accessor :geohash, :name

    def initialize(string: nil, geohash: nil, name: nil)
      if string.nil? && (geohash.nil? || name.nil?)
        raise(ArgumentError, 'argument must be either a onestop id string or both a geohash and name.')
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

    def to_s
      [self.class::PREFIX, @geohash, @name].join(COMPONENT_SEPARATOR)
    end

    def validate
      errors = []
      errors << 'invalid geohash' unless @geohash.present?
      errors << 'invalid name' unless @name.present?
      errors << 'invalid geohash' unless validate_geohash(@geohash)
      errors << 'invalid name' unless validate_name(@name)
      return (errors.size == 0), errors
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

  class StopOnestopId < OnestopIdBase
    PREFIX = :s
    MODEL = Stop
  end

  class RouteOnestopId < OnestopIdBase
    PREFIX = :r
    MODEL = Route
  end

  class RouteStopPatternOnestopId < OnestopIdBase
    PREFIX = :r
    MODEL = RouteStopPattern
    NUM_COMPONENTS = 5
    HASH_LENGTH = 6

    attr_accessor :stop_hash, :geometry_hash

    def initialize(string: nil, route_onestop_id: nil, stop_pattern: nil, geometry_coords: nil)
      if string && string.length > 0
        geohash = string.split(COMPONENT_SEPARATOR)[1]
        name = string.split(COMPONENT_SEPARATOR)[2]
        stop_hash = string.split(COMPONENT_SEPARATOR)[3]
        geometry_hash = string.split(COMPONENT_SEPARATOR)[4]
      else
        geohash = route_onestop_id.split(COMPONENT_SEPARATOR)[1].downcase.gsub(GEOHASH_FILTER, '')
        name = route_onestop_id.split(COMPONENT_SEPARATOR)[2].downcase.gsub(NAME_TILDE, '~').gsub(NAME_FILTER, '')
        stop_hash = generate_hash_from_array(stop_pattern)
        geometry_hash = generate_hash_from_array(geometry_coords)
      end
      @geohash = geohash
      @name = name
      @stop_hash = stop_hash
      @geometry_hash = geometry_hash
    end

    def to_s
      [self.class::PREFIX, @geohash, @name, @stop_hash, @geometry_hash].join(COMPONENT_SEPARATOR)
    end

    def validate
      errors = super[1]
      errors << 'invalid stop pattern hash' unless @stop_hash.present?
      errors << 'invalid stop pattern hash' unless validate_hash(@stop_hash)
      errors << 'invalid geometry hash' unless @geometry_hash.present?
      errors << 'invalid geometry hash' unless validate_hash(@geometry_hash)
      return (errors.size == 0), errors
    end

    def generate_hash_from_array(array)
      Digest::MD5.hexdigest(array.flatten.join(','))[0...HASH_LENGTH]
    end

    def self.route_onestop_id(onestop_id)
      onestop_id.split(COMPONENT_SEPARATOR)[0..2].join(COMPONENT_SEPARATOR)
    end

    private

    def validate_hash(value)
      (value.is_a? String) && value.length == HASH_LENGTH
    end
  end

  LOOKUP = Hash[OnestopId::OnestopIdBase.descendants.map { |c| [[c::PREFIX, c::NUM_COMPONENTS], c] }]
  LOOKUP_MODEL = Hash[OnestopId::OnestopIdBase.descendants.map { |c| [c::MODEL, c] }]

  def self.handler_by_string(string: nil)
    if string && string.length > 0
      split = string.split(COMPONENT_SEPARATOR)
      prefix = split[0].to_sym
      num_components = split.size
      LOOKUP[[prefix, num_components]]
    end
  end

  def self.handler_by_model(model)
    LOOKUP_MODEL[model]
  end

  def self.create_identifier(feed_onestop_id, entity_prefix, entity_id)
    IDENTIFIER_TEMPLATE.expand(
      feed_onestop_id: feed_onestop_id,
      entity_prefix: entity_prefix,
      entity_id: entity_id
    ).to_s
  end

  def self.validate_onestop_id_string(onestop_id, expected_entity_type: nil)
    klass = handler_by_string(string: onestop_id)
    return false, ['must not be empty'] if onestop_id.blank?
    return false, ['no matching handler'] unless klass
    klass.new(string: onestop_id).validate
  end

  def self.find(onestop_id)
    handler_by_string(string: onestop_id)::MODEL.find_by(onestop_id: onestop_id)
  end

  def self.find!(onestop_id)
    handler_by_string(string: onestop_id)::MODEL.find_by!(onestop_id: onestop_id)
  end
end
