class AddTypeToFeeds < ActiveRecord::Migration
  def change
    add_column :current_feeds, :type, :string, :null => false, :default => 'Feed'
    add_column :old_feeds, :type, :string, :null => false, :default => 'Feed'
  end
end
