class ChangeSspAccessibilityFromIntegers < ActiveRecord::Migration
  def change
    ["current","old"].each do |version|
      remove_column "#{version}_schedule_stop_pairs", :wheelchair_accessible, :integer
      remove_column "#{version}_schedule_stop_pairs", :bikes_allowed, :integer
      remove_column "#{version}_schedule_stop_pairs", :pickup_type, :integer
      remove_column "#{version}_schedule_stop_pairs", :drop_off_type, :integer
      add_column "#{version}_schedule_stop_pairs", :wheelchair_accessible, :boolean
      add_column "#{version}_schedule_stop_pairs", :bikes_allowed, :boolean
      add_column "#{version}_schedule_stop_pairs", :pickup_type, :string
      add_column "#{version}_schedule_stop_pairs", :drop_off_type, :string
    end
  end
end
