class AddTagsToFeed < ActiveRecord::Migration
  def change
    add_column :feeds, :tags, :hstore
  end
end
