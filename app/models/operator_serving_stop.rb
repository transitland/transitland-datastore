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

class BaseOperatorServingStop < ActiveRecord::Base
  self.abstract_class = true
end

class OperatorServingStop < BaseOperatorServingStop
  self.table_name_prefix = 'current_'

  include CurrentTrackedByChangeset
  current_tracked_by_changeset kind_of_model_tracked: :relationship

  def self.find_by_attributes(attrs = {})
    if attrs.keys.include?(:operator_onestop_id) && attrs.keys.include?(:stop_onestop_id)
      operator = Operator.find_by_onestop_id!(attrs[:operator_onestop_id])
      stop = Stop.find_by_onestop_id!(attrs[:stop_onestop_id])
      find_by(operator: operator, stop: stop)
    else
      raise ArgumentError.new('must specify Onestop IDs for an operator and for a stop')
    end
  end

  belongs_to :stop
  belongs_to :operator

  def before_destroy_making_history(changeset, old_model)
    if Stop.exists?(self.stop.id) && !self.stop.marked_for_destroy_making_history
      old_model.stop = self.stop
    elsif self.stop.old_model_left_after_destroy_making_history.present?
      old_model.stop = self.stop.old_model_left_after_destroy_making_history
    else
      raise 'about to create a broken OldOperatorServingStop record'
    end

    if Operator.exists?(self.operator.id) && !self.operator.marked_for_destroy_making_history
      old_model.operator = self.operator
    elsif self.operator.old_model_left_after_destroy_making_history.present?
      old_model.operator = self.operator.old_model_left_after_destroy_making_history
    else
      raise 'about to create a broken OldOperatorServingStop record'
    end
  end
end

class OldOperatorServingStop < BaseOperatorServingStop
  include OldTrackedByChangeset

  belongs_to :stop, polymorphic: true
  belongs_to :operator, polymorphic: true
end
