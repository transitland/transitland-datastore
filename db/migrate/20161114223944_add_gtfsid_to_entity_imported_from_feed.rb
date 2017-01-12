class AddGtfsidToEntityImportedFromFeed < ActiveRecord::Migration
  def change
    add_column :entities_imported_from_feed, :gtfs_id, :string
  end
end
