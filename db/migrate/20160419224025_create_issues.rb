class CreateIssues < ActiveRecord::Migration
  def change
    create_table :issues do |t|
      t.references :created_by_changeset, class_name: "Changeset", null: false
      t.references :resolved_by_changeset, class_name: "Changeset"
      t.string :details
      t.string :issue_type
      t.boolean :block_changeset_apply, default: false
      t.timestamps
    end
  end
end
