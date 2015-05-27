class CreateFeedsAndFeedImports < ActiveRecord::Migration
  def change
    create_table :feeds do |t|
      t.string :onestop_id
      t.string :url
      t.string :feed_format
      t.hstore :tags
      t.string :last_sha1
      t.datetime :last_fetched_at
      t.datetime :last_imported_at
      t.timestamps
    end
    add_index :feeds, :onestop_id

    create_table :feed_imports do |t|
      t.references :feed, index: true
      t.boolean :success
      t.string :sha1
      t.text :import_log
      t.text :validation_report
      t.timestamps
    end
  end
end
