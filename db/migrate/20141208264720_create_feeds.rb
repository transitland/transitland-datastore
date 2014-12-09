class CreateFeeds < ActiveRecord::Migration
  def change
    create_table :feeds do |t|
      t.string :url
      t.string :feed_format
      t.datetime :last_fetched_at
      t.datetime :last_imported_at
      t.timestamps
    end

    create_table :operators_in_feed do |t|
      t.references :feed, index: true
      t.references :operator, index: true
      t.string :onestop_id
      t.string :gtfs_agency_id
      t.timestamps
    end

    create_table :feed_imports do |t|
      t.references :feed, index: true
      t.boolean :successful_fetch
      t.boolean :successful_import
      t.attachment :file
      t.string :file_fingerprint
      t.timestamps
    end

    create_table :feed_import_errors do |t|
      t.references :feed_import, index: true
      t.string :error_type
      t.text :body
      t.timestamps
    end
  end
end
