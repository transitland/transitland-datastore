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
  end

  private

  def add_changeset_assocation(table)
    add_column table, :created_or_updated_in_changeset_id, :integer
    add_index  table, :created_or_updated_in_changeset_id, name: "#{table}_cu_in_changeset_id_index"
    add_column table, :destroyed_in_changeset_id, :integer
    add_index  table, :destroyed_in_changeset_id, name: "#{table}_d_in_changeset_id_index"
    add_column table, :version, :integer
    add_column table, :current, :boolean
    add_index  table, :current
  end
end
