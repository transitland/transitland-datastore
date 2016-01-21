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

    #STOP_PATTERN_MATCH = /^[S][1-9][0-9]*$/
    #GEOMETRY_MATCH = /^[G][1-9][0-9]*$/
    PREFIX = :r
    MODEL = RouteStopPattern
    NUM_COMPONENTS = 5

    attr_accessor :stop_pattern_index, :geometry_index

    def initialize(string: nil, route_onestop_id: nil, stop_pattern_index: nil, geometry_index: nil)
      if string && string.length > 0
        geohash = string.split(COMPONENT_SEPARATOR)[1]
        name = string.split(COMPONENT_SEPARATOR)[2]
        stop_pattern_index = self.class.onestop_id_component_num(string, :stop_pattern)
        geometry_index = self.class.onestop_id_component_num(string, :geometry)
      else
        geohash = route_onestop_id.split(COMPONENT_SEPARATOR)[1].downcase.gsub(GEOHASH_FILTER, '')
        name = route_onestop_id.split(COMPONENT_SEPARATOR)[2].downcase.gsub(NAME_TILDE, '~').gsub(NAME_FILTER, '')
      end
      @geohash = geohash
      @name = name
      @stop_pattern_index = stop_pattern_index
      @geometry_index = geometry_index
    end

    def to_s
      [self.class::PREFIX, @geohash, @name, "S#{@stop_pattern_index}", "G#{@geometry_index}"].join(COMPONENT_SEPARATOR)
    end

    def validate
      errors = super[1]
      errors << 'invalid stop pattern index' unless @stop_pattern_index.present?
      errors << 'invalid geometry index' unless @geometry_index.present?
      errors << 'invalid stop pattern index' unless validate_index(@stop_pattern_index)
      errors << 'invalid geometry index' unless validate_index(@geometry_index)
      return (errors.size == 0), errors
    end

    def self.component_count(route_onestop_id, component)
      case component
      when :stop_pattern
        num = 3
      when :geometry
        num = 4
      else
        raise ArgumentError.new('component must be stop_pattern or geometry')
      end
      RouteStopPattern.where(route: Route.find_by(onestop_id: route_onestop_id))
      .pluck(:onestop_id).map {|onestop_id| onestop_id.split(COMPONENT_SEPARATOR)[num] }.uniq.size
    end

    def self.onestop_id_component_num(onestop_id, component)
      case component
      when :stop_pattern
        return onestop_id.split(COMPONENT_SEPARATOR)[3].tr('S','').to_i
      when :geometry
        return onestop_id.split(COMPONENT_SEPARATOR)[4].tr('G','').to_i
      else
        raise ArgumentError.new('component must be stop_pattern or geometry')
      end
    end

    def self.route_onestop_id(onestop_id)
      onestop_id.split(COMPONENT_SEPARATOR)[0..2].join(COMPONENT_SEPARATOR)
    end

    private

    def validate_index(value)
      (value.is_a? Integer) && value != 0
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
