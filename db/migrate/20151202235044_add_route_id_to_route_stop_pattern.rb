class AddRouteIdToRouteStopPattern < ActiveRecord::Migration
  def change
    add_column :current_route_stop_patterns, :route_id, :string
    add_column :old_route_stop_patterns, :route_id, :string
  end
end
