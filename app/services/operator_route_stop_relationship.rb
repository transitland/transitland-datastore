class OperatorRouteStopRelationship
  include Virtus.model(strict: true)

  attribute :operator_onestop_id, String
  attribute :stop_onestop_id, String
  attribute :does_operator_serve_stop, Boolean

  def operator_onestop_id=(new_value)
    is_a_valid_onestop_id, errors = OnestopId.validate_onestop_id_string(new_value, expected_entity_type: 'operator')
    super(new_value) if is_a_valid_onestop_id
  end

  def stop_onestop_id=(new_value)
    is_a_valid_onestop_id, errors = OnestopId.validate_onestop_id_string(new_value, expected_entity_type: 'stop')
    super(new_value) if is_a_valid_onestop_id
  end

  def apply_change(in_changeset: changeset)
    operator = Operator.find_by_onestop_id!(operator_onestop_id)
    stop = Stop.find_by_onestop_id!(stop_onestop_id)
    operator_serving_stop = OperatorServingStop.find_by(operator: operator, stop: stop)
    if operator_serving_stop && does_operator_serve_stop
      return # nothing to do
    elsif operator_serving_stop && !does_operator_serve_stop
      operator_serving_stop.destroy_making_history(changeset: in_changeset)
    elsif operator_serving_stop.nil? && does_operator_serve_stop
      OperatorServingStop.create_making_history(changeset: in_changeset, new_attrs: {
        operator_id: operator.id,
        stop_id: stop.id
      })
    elsif operator_serving_stop.nil? && !does_operator_serve_stop
      return # nothing to do
    else
      raise 'something went wrong trying to apply OperatorRouteStopRelationship'
    end
  end
end
