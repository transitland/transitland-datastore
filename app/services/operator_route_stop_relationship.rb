class OperatorRouteStopRelationship
  # object to modify an individual relationship
  attr_accessor :operator_onestop_id,
                :stop_onestop_id,
                :operator,
                :stop,
                :does_operator_serve_stop

  def initialize(operator_onestop_id: nil, stop_onestop_id: nil, operator: nil, stop: nil, does_operator_serve_stop: nil)
    if operator
      @operator = operator
    elsif operator_onestop_id
      @operator = Operator.find_by_onestop_id!(operator_onestop_id)
    else
      raise 'must specify an operator by model or Onestop ID'
    end

    if stop
      @stop = stop
    elsif stop_onestop_id
      @stop = Stop.find_by_onestop_id!(stop_onestop_id)
    else
      raise 'must specify an stop by model or Onestop ID'
    end

    if !!does_operator_serve_stop == does_operator_serve_stop # is a boolean
      @does_operator_serve_stop = does_operator_serve_stop
    else
      raise 'must specify whether operator serves stop as a boolean'
    end
  end

  def apply_change(in_changeset: nil)
    operator_serving_stop = OperatorServingStop.find_by(operator: @operator, stop: @stop)
    if !!operator_serving_stop && @does_operator_serve_stop
      return # nothing to do
    elsif !!operator_serving_stop && !@does_operator_serve_stop
      operator_serving_stop.destroy_making_history(changeset: in_changeset)
    elsif !operator_serving_stop && @does_operator_serve_stop
      # binding.pry
      OperatorServingStop.create_making_history(changeset: in_changeset, new_attrs: {
        operator_id: @operator.id,
        stop_id: @stop.id
      })
    elsif !operator_serving_stop && !@does_operator_serve_stop
      return # nothing to do
    else
      raise 'something went wrong trying to apply OperatorRouteStopRelationship'
    end
  end

  # class methods for management of multiple relationships

  def self.manage_multiple(stop: {}, operator: {}, changeset: nil)
    relationships_to_apply = []

    relationships_to_apply += relationships_to_apply_for_stop(stop) unless stop.blank?
    relationships_to_apply += relationships_to_apply_for_operator(operator) unless operator.blank?

    relationships_to_apply.each { |relationship| relationship.apply_change(in_changeset: changeset) }
    return true
  end

  private

  def self.relationships_to_apply_for_stop(stop)
    raw_relationships = {}
    relationships_to_apply = []

    stop[:served_by].each     { |onestop_id| raw_relationships[onestop_id] = true  }
    stop[:not_served_by].each { |onestop_id| raw_relationships[onestop_id] = false }

    raw_relationships.each do |onestop_id, will_be_served|
      served_by_entity = OnestopIdService.find!(onestop_id)
      case served_by_entity
      when Operator
        relationships_to_apply << OperatorRouteStopRelationship.new(
          operator: served_by_entity,
          stop: stop[:model],
          does_operator_serve_stop: will_be_served
        )
      end
    end

    relationships_to_apply
  end

  def self.relationships_to_apply_for_operator(operator)
    raw_relationships = {}
    relationships_to_apply = []

    operator[:serves].each         { |onestop_id| raw_relationships[onestop_id] = true  }
    operator[:does_not_serve].each { |onestop_id| raw_relationships[onestop_id] = false }

    raw_relationships.each do |onestop_id, will_serve|
      serves_entity = OnestopIdService.find!(onestop_id)
      case serves_entity
      when Stop
        relationships_to_apply << OperatorRouteStopRelationship.new(
          operator: operator[:model],
          stop: serves_entity,
          does_operator_serve_stop: will_serve
        )
      end
    end

    relationships_to_apply
  end
end
