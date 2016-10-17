class AddExactTimesToScheduleStopPairs < ActiveRecord::Migration
  def change
    ["current", "old"].each do |version|
      add_column "#{version}_schedule_stop_pairs", :frequency_exact_times, :boolean
      add_index "#{version}_schedule_stop_pairs", :frequency_exact_times 
    end
  end
end
