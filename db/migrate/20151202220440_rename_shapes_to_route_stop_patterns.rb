class RenameShapesToRouteStopPatterns < ActiveRecord::Migration
  def change
    rename_table :current_shapes, :current_route_stop_patterns
    rename_table :old_shapes, :old_route_stop_patterns
  end
end
