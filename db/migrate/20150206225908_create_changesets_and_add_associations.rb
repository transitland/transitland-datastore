class CreateChangesetsAndAddAssociations < ActiveRecord::Migration
  def change
    create_table :changesets do |t|
      t.text :notes
      t.boolean :applied
      t.datetime :applied_at
      t.json :payload
      t.timestamps
    end

    add_changeset_assocation(:operators)
    add_changeset_assocation(:stops)
    add_changeset_assocation(:identifiers)
    add_changeset_assocation(:operators_serving_stop)

    change_to_accept_both_current_and_old_entities(:operators_serving_stop, :stop)
    change_to_accept_both_current_and_old_entities(:operators_serving_stop, :operator)
  end

  private

  def add_changeset_assocation(table)
    ActiveRecord::Base.connection.execute("CREATE TABLE old_#{table} AS SELECT * FROM #{table} WITH NO DATA;")

    rename_table table, "current_#{table}"
    add_column "current_#{table}", :created_or_updated_in_changeset_id, :integer
    add_index  "current_#{table}", :created_or_updated_in_changeset_id, name: "#c_#{table}_cu_in_changeset_id_index"
    add_column "current_#{table}", :version, :integer

    add_column "old_#{table}", :created_or_updated_in_changeset_id, :integer
    add_index  "old_#{table}", :created_or_updated_in_changeset_id, name: "o_#{table}_cu_in_changeset_id_index"
    add_column "old_#{table}", :destroyed_in_changeset_id, :integer
    add_index  "old_#{table}", :destroyed_in_changeset_id, name: "#{table}_d_in_changeset_id_index"
    add_column "old_#{table}", :current_id, :integer
    add_index  "old_#{table}", :current_id
    add_column "old_#{table}", :version, :integer
  end

  def change_to_accept_both_current_and_old_entities(table, association)
    add_column   "old_#{table}", "#{association}_type", :string
    # remove_index "old_#{table}", "#{association}_id"
    add_index    "old_#{table}", ["#{association}_type", "#{association}_id"], name: "#{table}_#{association}"
  end
end
