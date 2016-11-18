class AddExactTimesToScheduleStopPairs < ActiveRecord::Migration
  def change
    ["current", "old"].each do |version|
      add_column "#{version}_schedule_stop_pairs", :frequency_type, :string
      add_index "#{version}_schedule_stop_pairs", :frequency_type
      remove_column "#{version}_schedule_stop_pairs", :frequency_headway_seconds
      add_column "#{version}_schedule_stop_pairs", :frequency_headway_seconds, :integer
    end
  end
end
