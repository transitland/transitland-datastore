class FeedStates < ActiveRecord::Migration
  def change
    create_table :feed_states do |t|
      t.references :feed, null: false
      t.integer :feed_version_id
      t.datetime :last_fetched_at
      t.datetime :last_successful_fetch_at
      t.datetime :last_imported_at
      t.string :last_fetch_error, null: false, default: ""
      t.boolean :realtime_enabled, null: false, default: false
      t.integer :priority
      t.st_polygon :geometry, geographic: true
      t.json :tags
      t.timestamps
    end
    add_foreign_key :feed_states, :current_feeds, column: :feed_id
    add_foreign_key :feed_states, :feed_versions, column: :feed_version_id
    add_index :feed_states, :feed_id, unique: true
    add_index :feed_states, :feed_version_id, unique: true
    add_index :feed_states, :priority, unique: true
  end
end
