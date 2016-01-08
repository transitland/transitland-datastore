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

    def initialize(string: nil, geohash: nil, name: nil, entity_prefix: nil)
      if string && string.length > 0
        @geohash = string.split(COMPONENT_SEPARATOR)[1]
        @name = string.split(COMPONENT_SEPARATOR)[2]
      elsif geohash && name
        # Filter geohash and name; validate later
        @geohash = geohash_filter(geohash)
        @name = name_filter(name)
      else
        raise ArgumentError.new('either a string or entity/geohash/name must be specified')
      end
      # Check valid OnestopID
      is_a_valid_onestop_id, errors = self.validate(self.to_s)
      if !is_a_valid_onestop_id
        raise ArgumentError.new(errors.join(', '))
      end
      self
    end

    def to_s
      [self.class::PREFIX, @geohash, @name].join(COMPONENT_SEPARATOR)
    end

    def validate(value)
      split = value.split(COMPONENT_SEPARATOR)
      errors = []
      errors << 'must not be empty' if value.blank?
      errors << 'incorrect length' unless split.size == self.class::NUM_COMPONENTS
      errors << 'invalid geohash' unless validate_geohash(split[1])
      errors << 'invalid name' unless validate_name(split[2])
      # errors << 'invalid suffix' unless validate_suffix(split[3])
      return (errors.size == 0), errors
    end

    def validate_geohash(value)
      !(value =~ GEOHASH_FILTER)
    end

    def validate_name(value)
      !(value =~ NAME_FILTER)
    end

    def validate_prefix(value)
      value == self.PREFIX
    end

    def validate_suffix(value)
      true
    end

    private

    def name_filter(value)
      value.downcase.gsub(NAME_TILDE, '~').gsub(NAME_FILTER, '')
    end

    def geohash_filter(value)
      value.downcase.gsub(GEOHASH_FILTER, '')
    end
  end

  class OperatorOnestopId < OnestopIdBase
    PREFIX = :o
    MODEL = Operator
  end

  class FeedOnestopId < OnestopIdBase
    PREFIX = :f
  end

  class StopOnestopId < OnestopIdBase
    PREFIX = :s
  end

  class RouteOnestopId < OnestopIdBase
    PREFIX = :r
  end

  class RouteStopPatternOnestopId < OnestopIdBase
    PREFIX = :r
    # MODEL = RouteStopPattern
    NUM_COMPONENTS = 4
  end

  def OnestopId.lookup(string)
    split = string.split(COMPONENT_SEPARATOR)
    prefix = split[0]
    prefix = prefix.to_sym if prefix
    lookup = Hash[OnestopId::OnestopIdBase.descendants.map { |c| [[c::PREFIX, c::NUM_COMPONENTS], c] }]
    lookup[[prefix, split.size]]
  end

  def OnestopId.create_identifier(feed_onestop_id, entity_prefix, entity_id)
    IDENTIFIER_TEMPLATE.expand(
      feed_onestop_id: feed_onestop_id,
      entity_prefix: entity_prefix,
      entity_id: entity_id
    ).to_s
  end

  def OnestopId.validate_onestop_id_string(onestop_id)
    binding.pry
    klass = lookup(onestop_id)
    return false, ['invalid prefix'] unless klass
    klass.new(string: onestop_id).validate(onestop_id)
  end

  def OnestopId.find(onestop_id)
    lookup(onestop_id)::MODEL.find_by(onestop_id: onestop_id)
  end

  def OnestopId.find!(onestop_id)
    lookup(onestop_id)::MODEL.find_by!(onestop_id: onestop_id)
  end

  # def OnestopId.entity_prefix(onestop_id)
  #   onestop_id.split(COMPONENT_SEPARATOR)[0]
  # end

  # def OnestopId.model_from_prefix(prefix)
  #   ENTITY_TO_MODEL.fetch(ENTITY_TO_MODEL.keys.find {|entity| entity::PREFIX == prefix}, nil)
  # end

  def OnestopId.new(*args)
    StopOnestopId.new(*args)
  end

  def OnestopId.build(model, *args)
    MODEL_TO_ENTITY[model].new(*args)
  end

=begin
  class RouteStopPatternOnestopId < OnestopIdBase

    PREFIX = 'r'
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
        RouteStopPatternOnestopId.route_onestop_id(onestop_id)
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
  end
=end

end
