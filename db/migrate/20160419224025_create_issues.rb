class CreateIssues < ActiveRecord::Migration
  def change
    create_table :issues do |t|
      t.references :feed_version, class_name: "FeedVersion"
      t.references :created_by_changeset, class_name: "Changeset"
      t.references :resolved_by_changeset, class_name: "Changeset"
      t.string :description
      t.boolean :block_import_changeset_apply, default: false
      t.timestamps
    end
  end
end
