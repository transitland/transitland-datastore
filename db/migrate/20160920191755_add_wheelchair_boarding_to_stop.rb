class AddWheelchairBoardingToStop < ActiveRecord::Migration
  def change
    ["current", "old"].each do |version|
      add_column "#{version}_stops", :wheelchair_boarding, :boolean
      add_index "#{version}_stops", :wheelchair_boarding 
    end
  end
end
