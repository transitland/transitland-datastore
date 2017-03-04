class AddGeometrySourceToRouteStopPattern < ActiveRecord::Migration
  def change
    [:current, :old].each do |version|
      add_column "#{version}_route_stop_patterns", :geometry_source, :string, index: true
      remove_column "#{version}_route_stop_patterns", :is_generated
    end
  end
end
