class RemoveRspTrips < ActiveRecord::Migration
  def change
    remove_column :current_route_stop_patterns, :trips
    remove_column :old_route_stop_patterns, :trips
  end
end
