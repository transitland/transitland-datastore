class DmfrCleanup < ActiveRecord::Migration
  def change
    rename_column :feed_version_gtfs_imports, :succeeded, :success
  end
end
