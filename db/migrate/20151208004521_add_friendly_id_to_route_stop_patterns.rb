class AddFriendlyIdToRouteStopPatterns < ActiveRecord::Migration
  def change
    add_column :current_route_stop_patterns, :friendly_id, :string
    add_column :old_route_stop_patterns, :friendly_id, :string
  end
end
