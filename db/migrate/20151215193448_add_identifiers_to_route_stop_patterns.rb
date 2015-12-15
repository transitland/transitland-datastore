class AddIdentifiersToRouteStopPatterns < ActiveRecord::Migration
  def change
    add_column :current_route_stop_patterns, :identifiers, :string, array: true, index: true, default: []
    add_column :old_route_stop_patterns, :identifiers, :string, array: true, index: true, default: []
  end
end
