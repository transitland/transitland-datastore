# == Schema Information
#
# Table name: operators_serving_stop
#
#  id                                 :integer          not null, primary key
#  stop_id                            :integer          not null
#  operator_id                        :integer          not null
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  created_or_updated_in_changeset_id :integer
#  destroyed_in_changeset_id          :integer
#  version                            :integer
#  current                            :boolean
#
# Indexes
#
#  index_operators_serving_stop_on_current                  (current)
#  index_operators_serving_stop_on_operator_id              (operator_id)
#  index_operators_serving_stop_on_stop_id                  (stop_id)
#  index_operators_serving_stop_on_stop_id_and_operator_id  (stop_id,operator_id) UNIQUE
#  operators_serving_stop_cu_in_changeset_id_index          (created_or_updated_in_changeset_id)
#  operators_serving_stop_d_in_changeset_id_index           (destroyed_in_changeset_id)
#

FactoryGirl.define do
  factory :operator_serving_stop do
    operator
    stop
    current true
  end
end
