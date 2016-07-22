require 'addressable/template'

module OnestopId

  COMPONENT_SEPARATOR = '-'
  GEOHASH_FILTER = /[^0123456789bcdefghjkmnpqrstuvwxyz]/
  HEX_FILTER = /\H/
  NAME_TILDE = /[\-\:\&\@\/]/
  NAME_FILTER = /[^[:alnum:]\~\>\<]/
  IDENTIFIER_TEMPLATE = Addressable::Template.new("gtfs://{feed_onestop_id}/{entity_prefix}/{entity_id}")

  class OnestopIdError < StandardError
  end

  class OnestopIdBase

    PREFIX = nil
    MODEL = nil
    MAX_LENGTH = 64
    GEOHASH_MAX_LENGTH = 10
    NAME_MAX_LENGTH = 36

    def initialize(string: nil, **components)
      components = components.merge(self.parse(string)) if string
      components.each do |component, value|
        self.send("#{component}=", value)
      end
    end

    def self.match?(value)
      self.get_regex.match(value)
    end

    def self.get_regex
      # Cache
      self::REGEX ||= self.regex
    end

    def self.regex
      /^(?<prefix>#{self::PREFIX})-(?<geohash>[0-9a-z]+)-(?<name>[[:alnum:]~]+)$/
    end

    def to_s
      "#{prefix}-#{geohash[0...self.class::GEOHASH_MAX_LENGTH]}-#{name[0...self.class::NAME_MAX_LENGTH]}"[0...self.class::MAX_LENGTH]
    end

    def validate!
      valid, errors = self.validate
      fail OnestopIdError.new(errors.join(', ')) unless valid
    end

    def parse(string)
      match = self.class.regex.match(string)
      fail OnestopIdError.new('Could not parse') unless match
      Hash[match.names.zip(match.captures)]
    end

    def valid?
      return validate[0]
    end

    def errors
      return validate[1]
    end

    ##### Component handlers #####

    def prefix
      self.class::PREFIX
    end
    def prefix=(value)
    end

    def geohash
      @geohash
    end
    def geohash=(value)
      @geohash = value.downcase.gsub(GEOHASH_FILTER, '')
    end

    def name
      @name
    end
    def name=(value)
      @name = value.downcase.gsub(NAME_TILDE, '~').gsub(NAME_FILTER, '')
    end

    def validate
      errors = []
      errors << 'invalid geohash' unless geohash.present?
      errors << 'invalid name' unless name.present?
      return (errors.size == 0), errors
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

  class StopEgressOnestopId < OnestopIdBase
    PREFIX = :s
    MODEL = StopEgress

    def self.regex
      /^(?<prefix>#{self::PREFIX})-(?<geohash>[0-9a-z]+)-(?<name>[[:alnum:]~]+)>(?<suffix>[[:alnum:]~]+)$/
    end

    def to_s
      "#{prefix}-#{geohash[0...self.class::GEOHASH_MAX_LENGTH]}-#{name[0...self.class::NAME_MAX_LENGTH]}>#{suffix[0...14]}"[0...self.class::MAX_LENGTH]
    end

    def suffix
      @suffix
    end
    def suffix=(value)
      @suffix = value.downcase.gsub(self.class::NAME_TILDE, '~').gsub(NAME_FILTER, '')
    end
  end

  class StopPlatformOnestopId < OnestopIdBase
    PREFIX = :s
    MODEL = StopPlatform

    def self.regex
      /^(?<prefix>#{self::PREFIX})-(?<geohash>[0-9a-z]+)-(?<name>[[:alnum:]~]+)<(?<suffix>[[:alnum:]~]+)$/
    end

    def to_s
      "#{prefix}-#{geohash[0...self.class::GEOHASH_MAX_LENGTH]}-#{name[0...self.class::NAME_MAX_LENGTH]}<#{suffix[0...14]}"[0...self.class::MAX_LENGTH]
    end

    def suffix
      @suffix
    end
    def suffix=(value)
      @suffix = value.downcase.gsub(NAME_TILDE, '~').gsub(NAME_FILTER, '')
    end
  end

  class RouteOnestopId < OnestopIdBase
    PREFIX = :r
    MODEL = Route
  end

  class RouteStopPatternOnestopId < OnestopIdBase
    PREFIX = :r
    MODEL = RouteStopPattern
    HASH_LENGTH = 6

    def self.regex
      /^(?<prefix>#{self::PREFIX})-(?<geohash>[0-9a-z]+)-(?<name>[[:alnum:]~]+)-(?<stop_hash>\h+)-(?<geometry_hash>\h+)$/
    end

    def to_s
      "#{prefix}-#{geohash[0...self.class::GEOHASH_MAX_LENGTH]}-#{name[0...self.class::NAME_MAX_LENGTH]}-#{stop_hash[0...self.class::HASH_LENGTH]}-#{geometry_hash[0...self.class::HASH_LENGTH]}"[0...self.class::MAX_LENGTH]
    end

    def stop_hash
      @stop_hash
    end
    def stop_hash=(value)
      @stop_hash = value.downcase.gsub(HEX_FILTER, '~')
    end
    def stop_pattern=(value)
      self.stop_hash = self.generate_hash_from_array(value)[0...6]
    end

    def geometry_hash
      @geometry_hash
    end
    def geometry_hash=(value)
      @geometry_hash = value.downcase.gsub(HEX_FILTER, '~')
    end
    def geometry_coords=(value)
      self.geometry_hash = self.generate_hash_from_array(value)[0...6]
    end

    def route_onestop_id=(value)
      r = RouteOnestopId.new(string: value)
      self.geohash = r.geohash
      self.name = r.name
    end

    def validate
      errors = super[1]
      errors << 'invalid stop pattern hash' unless stop_hash.present?
      errors << 'invalid geometry hash' unless geometry_hash.present?
      return (errors.size == 0), errors
    end

    def generate_hash_from_array(array)
      Digest::MD5.hexdigest(array.flatten.join(','))
    end
  end

  LOOKUP_MODEL = Hash[OnestopId::OnestopIdBase.descendants.map { |c| [c::MODEL, c] }]

  def self.handler_by_string(string: nil)
    LOOKUP_MODEL.values.select { |cls| cls.match?(string) }.first
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
