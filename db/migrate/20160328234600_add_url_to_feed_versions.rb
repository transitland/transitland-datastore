class AddUrlToFeedVersions < ActiveRecord::Migration
  def change
    add_column :feed_versions, :url, :string
  end
end
