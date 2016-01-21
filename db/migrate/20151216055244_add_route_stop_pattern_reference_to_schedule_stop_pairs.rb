class AddRouteStopPatternReferenceToScheduleStopPairs < ActiveRecord::Migration
  def change
    add_reference :current_schedule_stop_pairs, :route_stop_pattern
    add_reference :old_schedule_stop_pairs, :route_stop_pattern
  end
end
