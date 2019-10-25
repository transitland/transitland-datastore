class DmfrCleanup < ActiveRecord::Migration
  def change
    rename_column :feed_version_gtfs_imports, :succeeded, :success
    add_column :feed_version_gtfs_imports, :error_count, :jsonb
    add_column :feed_version_gtfs_imports, :warning_count, :jsonb
    add_column :feed_version_gtfs_imports, :entity_count, :jsonb
  end
end
