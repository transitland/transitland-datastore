class AddShapeGenerationColumnsToRouteStopPatterns < ActiveRecord::Migration
  def change
    add_column :current_route_stop_patterns, :is_generated, :boolean, default: false
    add_column :current_route_stop_patterns, :is_modified, :boolean, default: false
    add_column :current_route_stop_patterns, :is_only_stop_points, :boolean, default: false

    add_column :old_route_stop_patterns, :is_generated, :boolean, default: false
    add_column :old_route_stop_patterns, :is_modified, :boolean, default: false
    add_column :old_route_stop_patterns, :is_only_stop_points, :boolean, default: false
  end
end
