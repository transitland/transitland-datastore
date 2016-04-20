class CreateEntitiesWithIssues < ActiveRecord::Migration
  def change
    create_table :entities_with_issues do |t|
      t.references :entity, polymorphic: true, index: true
      t.references :issue, class_name: "Issue"
      t.timestamps
    end
  end
end
