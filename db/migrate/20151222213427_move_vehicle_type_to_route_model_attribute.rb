class MoveVehicleTypeToRouteModelAttribute < ActiveRecord::Migration
  def change
    [:current, :old].each do |version|
      add_column "#{version}_routes", :vehicle_type, :integer
    end

    Route.find_each do |route|
      move_vehicle_type_from_tags_into_model_attribute(route)
    end

    OldRoute.find_each do |route|
      move_vehicle_type_from_tags_into_model_attribute(route)
    end
  end

  private

  def move_vehicle_type_from_tags_into_model_attribute(route)
    if route.tags.present? && route.tags['vehicle_type'].present?
      tags = route.tags
      existing_vehicle_type_string = tags.delete('vehicle_type')
      existing_vehicle_type_integer = GTFS::Route::VEHICLE_TYPES.invert[existing_vehicle_type_string.capitalize.to_sym].to_s.to_i
      route.update(
        vehicle_type: existing_vehicle_type_integer,
        tags: tags
      )
    end
  end
end
