class CreateIssueTypes < ActiveRecord::Migration
  def change
    create_table :issue_types do |t|
      t.string :type_name
      t.string :description
      t.string :category
      t.timestamps null: false
    end
  end
end
