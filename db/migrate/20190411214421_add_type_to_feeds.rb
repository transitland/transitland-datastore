class AddTypeToFeeds < ActiveRecord::Migration
  def change
    add_column :current_feeds, :type, :string, index: true
    add_column :old_feeds, :type, :string, index: true
    add_column :current_feeds, :authorization, :hstore, index: true
    add_column :old_feeds, :authorization, :hstore, index: true
    add_column :current_feeds, :urls, :hstore, index: true
    add_column :old_feeds, :urls, :hstore, index: true
  end
end
