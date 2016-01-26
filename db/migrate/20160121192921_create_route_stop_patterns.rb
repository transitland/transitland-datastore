class CreateRouteStopPatterns < ActiveRecord::Migration
  def change

    [:current_route_stop_patterns,:old_route_stop_patterns].each do |name|
      create_table name do |t|
        t.string :onestop_id
        t.geometry :geometry, geographic: true
        t.hstore :tags
        t.string :stop_pattern, array: true, default: []
        t.integer :version
        t.integer :created_or_updated_in_changeset_id
        t.boolean :is_generated, default: false
        t.boolean :is_modified, default: false
        t.string :trips, array: true, default: []
        t.string :identifiers, array: true, index: true, default: []
        t.timestamps null: false
      end
    end

    add_reference :current_route_stop_patterns, :route, index: true
    add_reference :old_route_stop_patterns, :route, index: true, polymorphic: true
  end
end
