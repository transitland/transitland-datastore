class AddTripIdsToRouteStopPatterns < ActiveRecord::Migration
  def change
    add_column :current_route_stop_patterns, :trips, :string, array: true, default: []
    add_column :old_route_stop_patterns, :trips, :string, array: true, default: []
  end
end
