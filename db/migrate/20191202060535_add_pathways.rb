class AddPathways < ActiveRecord::Migration
  def change
    create_table :gtfs_pathways, id: :bigserial do |t|
      t.bigint :feed_version_id, null: false
      t.string :pathway_id, null: false
      t.bigint :from_stop_id, null: false
      t.bigint :to_stop_id, null: false
      t.integer :pathway_mode, null: false
      t.integer :is_bidirectional, null: false
      t.float :length, null: false
      t.integer :traversal_time, null: false
      t.integer :stair_count, null: false
      t.float :max_slope, null: false
      t.float :min_width, null: false
      t.string :signposted_as, null: false
      t.string :reverse_signposted_as, null: false
      t.timestamps null: false
    end
    add_index "gtfs_pathways", ["feed_version_id", "pathway_id"], name: "index_gtfs_pathways_unique", unique: true, using: :btree
    add_index "gtfs_pathways", ["pathway_id"], name: "index_gtfs_pathways_on_pathway_id", using: :btree
    add_index "gtfs_pathways", ["from_stop_id"], name: "index_gtfs_pathways_on_from_stop_id", using: :btree
    add_index "gtfs_pathways", ["to_stop_id"], name: "index_gtfs_pathways_on_to_stop_id", using: :btree
    add_foreign_key "gtfs_pathways", "feed_versions", column: "feed_version_id"
    add_foreign_key "gtfs_pathways", "gtfs_stops", column: "from_stop_id"
    add_foreign_key "gtfs_pathways", "gtfs_stops", column: "to_stop_id"

    create_table :gtfs_levels, id: :bigserial do |t|
      t.bigint :feed_version_id, null: false
      t.string :level_id, null: false
      t.float :level_index, null: false
      t.string :level_name, null: false
      t.timestamps null: false
    end
    add_index "gtfs_levels", ["feed_version_id", "level_id"], name: "index_gtfs_levels_unique", unique: true, using: :btree
    add_index "gtfs_levels", ["level_id"], name: "index_gtfs_pathways_on_level_id", using: :btree
    add_foreign_key "gtfs_levels", "feed_versions", column: "feed_version_id"

    #####

    change_column_null :gtfs_stops, :level_id, true
    change_column :gtfs_stops, :level_id, :bigint, using: 'null'
    change_column_null :active_stops, :level_id, true
    change_column :active_stops, :level_id, :bigint, using: 'null'

    add_foreign_key "gtfs_stops", "gtfs_levels", column: "level_id"
    add_foreign_key "active_stops", "gtfs_levels", column: "level_id"
  end
end
