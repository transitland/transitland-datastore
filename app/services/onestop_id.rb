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

class RouteStopPatternOnestopId < OnestopId

  STOP_PATTERN_MATCH = /^[S][0-9]+[0-9]$/
  GEOMETRY_MATCH = /^[G][0-9]+[0-9]$/

  # these are identifier components
  attr_accessor :stop_pattern, :geometry

  def initialize(string: nil, route_onestop_id: nil, stop_pattern_num: nil, geometry_num: nil)
    if string && string.length > 0
      @entity_prefix = string.split(COMPONENT_SEPARATOR)[0]
      @geohash = string.split(COMPONENT_SEPARATOR)[1]
      @name = string.split(COMPONENT_SEPARATOR)[2]
      @stop_pattern = string.split(COMPONENT_SEPARATOR)[3]
      @geometry = string.split(COMPONENT_SEPARATOR)[4]
    elsif route_onestop_id && stop_pattern_num && geometry_num
      @entity_prefix = route_onestop_id.split(COMPONENT_SEPARATOR)[0]
      @geohash = route_onestop_id.split(COMPONENT_SEPARATOR)[1]
      @name = route_onestop_id.split(COMPONENT_SEPARATOR)[2]
      @stop_pattern = stop_pattern_num
      @geometry = geometry_num
    else
      raise ArgumentError.new('either a string or route_onestop_id/stop_pattern_num/geometry_num must be specified')
    end
    # Check valid OnestopID
    is_a_valid_onestop_id, errors = RouteStopPatternOnestopId.validate_onestop_id_string(self.to_s)
    if !is_a_valid_onestop_id
      raise ArgumentError.new(errors.join(', '))
    end
    self
  end

  def to_s
    [@entity_prefix, @geohash, @name, "S#{@stop_pattern}", "G#{@geometry}"].join(COMPONENT_SEPARATOR)
  end

  def self.route_onestop_id(onestop_id)
    onestop_id.split(COMPONENT_SEPARATOR)[0..2].join(COMPONENT_SEPARATOR)
  end

  def self.validate_onestop_id_string(onestop_id)
    errors = []
    is_a_valid_onestop_id = true

    if onestop_id.blank?
      return false, ['must not be blank']
    end

    if onestop_id.split(COMPONENT_SEPARATOR).length != 5
      errors << 'must include 5 components separated by hyphens ("-")'
      is_a_valid_onestop_id = false
    end

    is_a_valid_route_onestop_id, route_onestop_id_errors = super(
      RouteStopPatternOnestopId.route_onestop_id(onestop_id),
      expected_entity_type: 'route'
    )
    is_a_valid_onestop_id = is_a_valid_route_onestop_id if is_a_valid_onestop_id
    errors.concat(route_onestop_id_errors)

    return is_a_valid_onestop_id, errors
  end

  def self.valid_component?(component, value)
    return false if !value || value.length == 0
    if super(component, value)
      return true
    else
      case component
      when :stop_pattern
        return (value =~ STOP_PATTERN_MATCH) == 0 ? true : false
      when :geometry
        return (value =~ GEOMETRY_MATCH) == 0 ? true : false
      else
        return false
      end
    end
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

  def self.find(onestop_id)
    RouteStopPattern.find_by(onestop_id: onestop_id)
  end

  def self.find!(onestop_id)
    RouteStopPattern.find_by!(onestop_id: onestop_id)
  end

end
