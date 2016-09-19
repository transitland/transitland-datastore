class AddWheelchairAccessibleAndBikesAllowedToRoute < ActiveRecord::Migration
  def change
    ["current","old"].each do |version|
      add_column "#{version}_routes", :wheelchair_accessible, :string
      add_column "#{version}_routes", :bikes_allowed, :string
      add_index "#{version}_routes", :wheelchair_accessible
      add_index "#{version}_routes", :bikes_allowed
    end
  end
end
