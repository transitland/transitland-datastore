class RemoveIssueCreatedByChangesetNullConstraint < ActiveRecord::Migration
  def change
    change_column_null(:issues, :created_by_changeset_id, true)
  end
end
