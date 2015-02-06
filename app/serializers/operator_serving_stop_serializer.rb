# == Schema Information
#
# Table name: operators_serving_stop
#
#  id          :integer          not null, primary key
#  stop_id     :integer          not null
#  operator_id :integer          not null
#  tags        :hstore
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_operators_serving_stop_on_operator_id              (operator_id)
#  index_operators_serving_stop_on_stop_id                  (stop_id)
#  index_operators_serving_stop_on_stop_id_and_operator_id  (stop_id,operator_id) UNIQUE
#

class OperatorServingStopSerializer < ApplicationSerializer
  attributes :onestop_id,
             :tags,
             :created_at,
             :updated_at

  def onestop_id
    object.operator.onestop_id
  end
end
