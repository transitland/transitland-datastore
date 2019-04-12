class AddTypeToFeeds < ActiveRecord::Migration
  def change
    add_column :current_feeds, :type, :string
    add_column :old_feeds, :type, :string
    add_column :current_feeds, :authorization, :hstore
    add_column :old_feeds, :authorization, :hstore
    add_column :current_feeds, :urls, :hstore
    add_column :old_feeds, :urls, :hstore
  end
end
