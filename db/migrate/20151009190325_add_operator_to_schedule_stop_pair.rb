class AddOperatorToScheduleStopPair < ActiveRecord::Migration
  def up
    add_reference :current_schedule_stop_pairs, :operator, index: true
    add_reference :old_schedule_stop_pairs, :operator, index: true
    ScheduleStopPair.find_each do |ssp|
      ssp.operator = ssp.route.operator
      ssp.save!
    end
  end

  def down
    remove_reference :current_schedule_stop_pairs, :operator
    remove_reference :old_schedule_stop_pairs, :operator
  end
end
