class AddStopPatternToRouteStopPattern < ActiveRecord::Migration
  def change
    add_column :current_route_stop_patterns, :stop_pattern, :string
    add_column :old_route_stop_patterns, :stop_pattern, :string
  end
end
