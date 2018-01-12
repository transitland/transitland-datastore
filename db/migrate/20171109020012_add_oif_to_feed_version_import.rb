class AddOifToFeedVersionImport < ActiveRecord::Migration
  def change
    add_column :feed_version_imports, :operators_in_feed, :json
  end
end
