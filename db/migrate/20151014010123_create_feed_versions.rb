class CreateFeedVersions < ActiveRecord::Migration
  def change
    create_table :feed_versions do |t|
      t.references :feed, index: true, polymorphic: true
      t.attachment :file
      t.date :earliest_calendar_date
      t.date :latest_calendar_date
      t.string :sha1
      t.string :md5
      t.hstore :tags
      t.datetime :fetched_at
      t.datetime :imported_at
      t.timestamps
    end

    remove_column :current_feeds, :last_sha1
    remove_column :old_feeds, :last_sha1

    drop_table :feed_imports

    create_table :feed_version_imports do |t|
      t.references :feed_version, index: true
      t.timestamps
      t.boolean :success
      t.text :import_log
      t.text :exception_log
      t.text :validation_report
    end

    remove_reference :feed_schedule_imports, :feed_import
    add_reference :feed_schedule_imports, :feed_version_import, index: true
  end
end
