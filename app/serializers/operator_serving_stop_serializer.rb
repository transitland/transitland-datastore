# == Schema Information
#
# Table name: current_operators_serving_stop
#
#  id                                 :integer          not null, primary key
#  stop_id                            :integer          not null
#  operator_id                        :integer          not null
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#
# Indexes
#
#  #c_operators_serving_stop_cu_in_changeset_id_index               (created_or_updated_in_changeset_id)
#  index_current_operators_serving_stop_on_operator_id              (operator_id)
#  index_current_operators_serving_stop_on_stop_id                  (stop_id)
#  index_current_operators_serving_stop_on_stop_id_and_operator_id  (stop_id,operator_id) UNIQUE
#

class OperatorServingStopSerializer < ApplicationSerializer
  attributes :operator_onestop_id,
             :operator_name,
             :tags,
             :created_at,
             :updated_at

  def operator_onestop_id
    object.operator.onestop_id
  end

  def operator_name
    object.operator.name
  end
end
