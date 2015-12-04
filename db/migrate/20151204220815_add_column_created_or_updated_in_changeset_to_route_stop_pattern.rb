class AddColumnCreatedOrUpdatedInChangesetToRouteStopPattern < ActiveRecord::Migration
  def change
    add_column :current_route_stop_patterns, :created_or_updated_in_changeset, :integer
    add_column :old_route_stop_patterns, :created_or_updated_in_changeset, :integer
  end
end
