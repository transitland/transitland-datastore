require 'addressable/template'

module OnestopId

  COMPONENT_SEPARATOR = '-'
  GEOHASH_FILTER = /[^0123456789bcdefghjkmnpqrstuvwxyz]/
  NAME_TILDE = /[\-\:\&\@\/]/
  NAME_FILTER = /[^a-zA-Z\d\@\~]/
  IDENTIFIER_TEMPLATE = Addressable::Template.new("gtfs://{feed_onestop_id}/{entity_prefix}/{entity_id}")

  class OnestopIdBase

    PREFIX = nil
    MODEL = nil
    NUM_COMPONENTS = 3

    attr_accessor :geohash, :name

    def initialize(string: nil, geohash: nil, name: nil)
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

  LOOKUP = Hash[OnestopId::OnestopIdBase.descendants.map { |c| [[c::PREFIX, c::NUM_COMPONENTS], c] }]
  LOOKUP_MODEL = Hash[OnestopId::OnestopIdBase.descendants.map { |c| [c::MODEL, c] }]

  def self.lookup(string: nil, prefix: nil, num_components: 3)
    if string && string.length > 0
      split = string.split(COMPONENT_SEPARATOR)
      prefix = split[0]
      prefix = prefix.to_sym if prefix
      num_components = split.size
    end
    prefix = prefix.to_sym if prefix
    LOOKUP[[prefix, num_components]]
  end

  def self.create_identifier(feed_onestop_id, entity_prefix, entity_id)
    IDENTIFIER_TEMPLATE.expand(
      feed_onestop_id: feed_onestop_id,
      entity_prefix: entity_prefix,
      entity_id: entity_id
    ).to_s
  end

  def self.validate_onestop_id_string(onestop_id, expected_entity_type: nil)
    klass = lookup(string: onestop_id)
    return false, ['must not be empty'] if onestop_id.blank?
    return false, ['no matching handler'] unless klass
    klass.new(string: onestop_id).validate
  end

  def self.find(onestop_id)
    lookup(string: onestop_id)::MODEL.find_by(onestop_id: onestop_id)
  end

  def self.find!(onestop_id)
    lookup(string: onestop_id)::MODEL.find_by!(onestop_id: onestop_id)
  end

  def self.factory(model)
    LOOKUP_MODEL[model]
  end

  def self.new(*args)
    if !args.empty? && args[0].has_key?(:string)
      lookup(string: args[0][:string]).new(*args)
    elsif !args.empty? && args[0].has_key?(:entity_prefix)
      lookup(prefix: args[0][:entity_prefix]).new(*args)
    #elsif args[0].has_key?(:route_onestop_id)
      #RouteStopPatternOnestopId.new(*args)
    else
      raise ArgumentError.new('either a string or id components must be specified')
    end
  end
end
