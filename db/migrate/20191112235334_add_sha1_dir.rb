class AddSha1Dir < ActiveRecord::Migration
  def change
    add_column :feed_versions, :sha1_dir, :string
    change_null :feed_versions, :sha1, false
  end
end
