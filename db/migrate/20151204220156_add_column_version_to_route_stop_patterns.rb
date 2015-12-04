class AddColumnVersionToRouteStopPatterns < ActiveRecord::Migration
  def change
    add_column :current_route_stop_patterns, :version, :integer
    add_column :old_route_stop_patterns, :version, :integer
  end
end
