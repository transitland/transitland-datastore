class AddImportLevelToFeedVersion < ActiveRecord::Migration
  def change
    add_column :feed_versions, :import_level, :integer, default: 0
  end
end
