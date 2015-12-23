class AddVehicleTypeIndexToRoutes < ActiveRecord::Migration
  def change
    [:current, :old].each do |version|
      add_index "#{version}_routes", :vehicle_type
    end
  end
end
