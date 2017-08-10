class OperatorRouteStopRelationship
  # object to modify an individual relationship
  attr_accessor :operator_onestop_id,
                :stop_onestop_id,
                :operator,
                :stop,
                :route,
                :does_service_exist

  def initialize(operator_onestop_id: nil, stop_onestop_id: nil, route_onestop_id: nil, operator: nil, stop: nil, route: nil, does_service_exist: nil)
    if stop
      @stop = stop
    elsif stop_onestop_id
      @stop = Stop.find_by_onestop_id!(stop_onestop_id)
    else
      raise 'must specify an stop by model or Onestop ID'
    end

    if route
      @route = route
    elsif route_onestop_id
      @route = Route.find_by_onestop_id!(route_onestop_id)
    end

    if operator
      @operator = operator
    elsif operator_onestop_id
      @operator = Operator.find_by_onestop_id!(operator_onestop_id)
    elsif @route && @route.operator
      @operator = @route.operator
    else
      raise 'must specify an operator by model, by Onestop ID, or by route'
    end

    if !!does_service_exist == does_service_exist # is a boolean
      @does_service_exist = does_service_exist
    else
      raise 'must specify whether service exists as a boolean'
    end
  end

  def apply_relationship(changeset: nil)
    operator_serving_stop = OperatorServingStop.find_by(operator: @operator, stop: @stop)
    if !!operator_serving_stop && @does_service_exist
      # nothing to do
    elsif !!operator_serving_stop && !@does_service_exist
      operator_serving_stop.destroy_making_history(changeset: changeset)
    elsif !operator_serving_stop && @does_service_exist
      OperatorServingStop.create_making_history(changeset: changeset, new_attrs: {
        operator_id: @operator.id,
        stop_id: @stop.id
      })
    elsif !operator_serving_stop && !@does_service_exist
      # nothing to do
    else
      raise 'something went wrong trying to apply OperatorRouteStopRelationship'
    end

    if @route
      route_serving_stop = RouteServingStop.find_by(route: @route, stop: @stop)
      if !!route_serving_stop && @does_service_exist
        # nothing to do
      elsif !!route_serving_stop && !@does_service_exist
        route_serving_stop.destroy_making_history(changeset: changeset)
      elsif !route_serving_stop && @does_service_exist
        RouteServingStop.create_making_history(changeset: changeset, new_attrs: {
          route_id: @route.id,
          stop_id: @stop.id
        })
      elsif !route_serving_stop && !@does_service_exist
        # nothing to do
      else
        raise 'something went wrong trying to apply OperatorRouteStopRelationship'
      end
    end
  end

  # class methods for management of multiple relationships

  def self.manage_multiple(stop: {}, operator: {}, route: {}, changeset: nil)
    # served_by / not_served_by uniqueness handled by raw_relationships
    relationships_to_apply = []

    relationships_to_apply += relationships_to_apply_for_stop(stop) unless stop.blank?
    relationships_to_apply += relationships_to_apply_for_operator(operator) unless operator.blank?
    relationships_to_apply += relationships_to_apply_for_route(route) unless route.blank?

    relationships_to_apply.each { |relationship| relationship.apply_relationship(changeset: changeset) }
    return true
  end

  private

  def self.relationships_to_apply_for_stop(stop)
    raw_relationships = {}
    relationships_to_apply = []

    stop[:served_by].each     { |onestop_id| raw_relationships[onestop_id] = true  }
    stop[:not_served_by].each { |onestop_id| raw_relationships[onestop_id] = false }

    raw_relationships.each do |onestop_id, will_be_served|
      served_by_entity = OnestopId.find_current_and_old!(onestop_id)
      case served_by_entity
      when Operator
        relationships_to_apply << OperatorRouteStopRelationship.new(
          operator: served_by_entity,
          stop: stop[:model],
          does_service_exist: will_be_served
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
      serves_entity = OnestopId.find_current_and_old!(onestop_id)
      case serves_entity
      when Stop
        relationships_to_apply << OperatorRouteStopRelationship.new(
          operator: operator[:model],
          stop: serves_entity,
          does_service_exist: will_serve
        )
      end
    end

    relationships_to_apply
  end

  def self.relationships_to_apply_for_route(route)
    raw_relationships = {}
    relationships_to_apply = []

    route[:serves].each         { |onestop_id| raw_relationships[onestop_id] = true  }
    route[:does_not_serve].each { |onestop_id| raw_relationships[onestop_id] = false }

    raw_relationships.each do |onestop_id, will_serve|
      serves_entity = OnestopId.find_current_and_old!(onestop_id)
      case serves_entity
      when Stop
        relationships_to_apply << OperatorRouteStopRelationship.new(
          route: route[:model],
          stop: serves_entity,
          does_service_exist: will_serve
        )
      end
    end

    relationships_to_apply
  end
end
