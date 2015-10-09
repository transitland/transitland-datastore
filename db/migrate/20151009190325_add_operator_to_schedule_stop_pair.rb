class AddOperatorToScheduleStopPair < ActiveRecord::Migration
  def change
    add_reference :current_schedule_stop_pairs, :operator, index: true
    add_reference :old_schedule_stop_pairs, :operator, index: true
  end
end
