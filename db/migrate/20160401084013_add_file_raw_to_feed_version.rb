class AddFileRawToFeedVersion < ActiveRecord::Migration
  def change
    add_column :feed_versions, :file_raw, :string
    add_column :feed_versions, :sha1_raw, :string
    add_column :feed_versions, :md5_raw, :string
  end
end
