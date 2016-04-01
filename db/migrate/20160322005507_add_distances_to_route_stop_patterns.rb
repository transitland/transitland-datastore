class AddDistancesToRouteStopPatterns < ActiveRecord::Migration
  def change
    add_column :current_route_stop_patterns, :stop_distances, :float, array: true, default: []
    add_column :old_route_stop_patterns, :stop_distances, :float, array: true, default: []
  end
end
