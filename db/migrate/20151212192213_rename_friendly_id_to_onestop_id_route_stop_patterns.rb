class RenameFriendlyIdToOnestopIdRouteStopPatterns < ActiveRecord::Migration
  def change
    rename_column :current_route_stop_patterns, :friendly_id, :onestop_id
    rename_column :old_route_stop_patterns, :friendly_id, :onestop_id
  end
end
