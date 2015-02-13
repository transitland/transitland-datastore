# TODO: move this out to a "onestop-id-registry-ruby-wrapper" library

class OnestopId
  ENTITY_TO_PREFIX = {
    'stop' => 's',
    'operator' => 'o',
    'feed' => 'f'
  }
  PREFIX_TO_ENTITY = ENTITY_TO_PREFIX.invert
  PREFIX_TO_MODEL = {
    's' => Stop,
    'o' => Operator
  }
  MODEL_TO_PREFIX = PREFIX_TO_MODEL.invert
  COMPONENT_SEPARATOR = '-'

  attr_accessor :entity_prefix, :geohash, :name

  def initialize(string: nil, entity_prefix: nil, geohash: nil, name: nil)
    errors = []

    if string && string.length > 0
      is_a_valid_onestop_id, errors = OnestopId.validate_onestop_id_string(string)
      if is_a_valid_onestop_id
        @entity_prefix = string.split(COMPONENT_SEPARATOR)[0]
        @geohash = string.split(COMPONENT_SEPARATOR)[1]
        @name = string.split(COMPONENT_SEPARATOR)[2]
        self
      else
        raise ArgumentError.new(errors.join(', '))
      end
    elsif entity_prefix && geohash && name
      if OnestopId.valid_component?(:entity_prefix, entity_prefix)
        @entity_prefix = entity_prefix
      else
        errors << 'invalid entity prefix'
      end
      if OnestopId.valid_component?(:geohash, geohash)
        @geohash = geohash
      else
        errors << 'invalid geohash'
      end
      if OnestopId.valid_component?(:name, name)
        @name = name
      else
        errors << 'invalid name'
      end
    else
      errors << 'either a string or entity/geohash/name must be specified'
    end

    if errors.length > 0
      raise ArgumentError.new(errors.join(', '))
    else
      self
    end
  end

  def self.validate_onestop_id_string(onestop_id, expected_entity_type: nil)
    errors = []
    is_a_valid_onestop_id = true

    if onestop_id.split(COMPONENT_SEPARATOR).length != 3
      errors << 'must include 3 components separated by hyphens ("-")'
      is_a_valid_onestop_id = false
    end

    if expected_entity_type && onestop_id.split(COMPONENT_SEPARATOR)[0] != ENTITY_TO_PREFIX[expected_entity_type]
      errors << "must start with \"#{ENTITY_TO_PREFIX[expected_entity_type]}\" as its 1st component"
      is_a_valid_onestop_id = false
    elsif expected_entity_type == nil && !valid_component?(:entity_prefix, onestop_id.split(COMPONENT_SEPARATOR)[0])
      errors << "must start with \"#{ENTITY_TO_PREFIX.values.join(' or ')}\" as its 1st component"
      is_a_valid_onestop_id = false
    end

    if onestop_id.split(COMPONENT_SEPARATOR)[1].length == 0 || !valid_component?(:geohash, onestop_id.split(COMPONENT_SEPARATOR)[1])
      errors << 'must include a valid geohash as its 2nd component'
      is_a_valid_onestop_id = false
    end

    if !valid_component?(:name, onestop_id.split(COMPONENT_SEPARATOR)[2])
      errors << 'must include only letters and digits in its abbreviated name (the 3rd component)'
      is_a_valid_onestop_id = false
    end
    return is_a_valid_onestop_id, errors
  end

  private

  def self.valid_component?(component, value)
    return false if !value || value.length == 0
    case component
    when :entity_prefix
      ENTITY_TO_PREFIX.values.include?(value)
    when :geohash
      !(value =~ /[^a-z\d]/)
    when :name
      !(value =~ /[^a-zA-Z\d]/)
    else
      false
    end
  end
end
