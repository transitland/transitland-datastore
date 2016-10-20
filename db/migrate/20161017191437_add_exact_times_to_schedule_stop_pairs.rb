class AddExactTimesToScheduleStopPairs < ActiveRecord::Migration
  def change
    ["current", "old"].each do |version|
      add_column "#{version}_schedule_stop_pairs", :frequency_exact_times, :boolean
      add_index "#{version}_schedule_stop_pairs", :frequency_exact_times
      remove_column "#{version}_schedule_stop_pairs", :frequency_headway_seconds
      add_column "#{version}_schedule_stop_pairs", :frequency_headway_seconds, :integer
    end
  end
end
