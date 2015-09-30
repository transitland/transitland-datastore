class AddWindowAndTimepointsToScheduleStopPair < ActiveRecord::Migration
  def change
    [:current, :old].each do |version|
      remove_column "#{version}_schedule_stop_pairs", :timepoint
      add_column "#{version}_schedule_stop_pairs", :window_start, :string
      add_column "#{version}_schedule_stop_pairs", :window_end, :string
      add_column "#{version}_schedule_stop_pairs", :origin_timepoint_source, :string
      add_column "#{version}_schedule_stop_pairs", :destination_timepoint_source, :string
    end
  end
end
