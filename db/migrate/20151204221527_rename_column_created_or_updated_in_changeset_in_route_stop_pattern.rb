class RenameColumnCreatedOrUpdatedInChangesetInRouteStopPattern < ActiveRecord::Migration
  def change
    rename_column :current_route_stop_patterns, :created_or_updated_in_changeset, :created_or_updated_in_changeset_id
    rename_column :old_route_stop_patterns, :created_or_updated_in_changeset, :created_or_updated_in_changeset_id
  end
end
