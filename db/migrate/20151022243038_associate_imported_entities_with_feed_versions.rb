class AssociateImportedEntitiesWithFeedVersions < ActiveRecord::Migration
  def change
    add_reference :entities_imported_from_feed, :feed_version, index: true
  end
end
