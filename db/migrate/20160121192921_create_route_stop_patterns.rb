class CreateRouteStopPatterns < ActiveRecord::Migration
  def change

    [:current_route_stop_patterns,:old_route_stop_patterns].each do |name|
      create_table name do |t|
        t.string :onestop_id, index: true
        t.geometry :geometry, geographic: true
        t.hstore :tags
        t.string :stop_pattern, array: true, default: [], index: true
        t.integer :version
        t.boolean :is_generated, default: false
        t.boolean :is_modified, default: false
        t.string :trips, array: true, default: [], index: true
        t.string :identifiers, array: true, index: true, default: []
        t.timestamps null: false
      end
    end

    add_column :current_route_stop_patterns, :created_or_updated_in_changeset_id, :integer
    add_column :old_route_stop_patterns, :created_or_updated_in_changeset_id, :integer
    add_index :current_route_stop_patterns, :created_or_updated_in_changeset_id, name: 'c_rsp_cu_in_changeset'
    add_index :old_route_stop_patterns, :created_or_updated_in_changeset_id, name: 'o_rsp_cu_in_changeset'
    add_column :old_route_stop_patterns, :destroyed_in_changeset_id, :integer, index: true
    add_reference :current_route_stop_patterns, :route, index: true
    add_reference :old_route_stop_patterns, :route, index: true, polymorphic: true
  end
end
