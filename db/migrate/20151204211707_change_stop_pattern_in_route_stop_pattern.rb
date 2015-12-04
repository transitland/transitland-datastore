class ChangeStopPatternInRouteStopPattern < ActiveRecord::Migration
  def change
    remove_column :current_route_stop_patterns, :stop_pattern
    remove_column :old_route_stop_patterns, :stop_pattern
    add_column :current_route_stop_patterns, :stop_pattern, :string, array: true, default: []
    add_column :old_route_stop_patterns, :stop_pattern, :string, array: true, default: []
  end
end
