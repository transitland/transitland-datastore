class AddRouteStopPatternReferenceToScheduleStopPairs < ActiveRecord::Migration
  def change
    add_reference :current_schedule_stop_pairs, :route_stop_pattern, polymorphic: true
    add_reference :old_schedule_stop_pairs, :route_stop_pattern, polymorphic: true
  end
end
