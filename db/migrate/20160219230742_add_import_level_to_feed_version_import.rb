class AddImportLevelToFeedVersionImport < ActiveRecord::Migration
  def change
    add_column :feed_version_imports, :import_level, :integer, index: true
  end
end
