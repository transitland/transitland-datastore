class AddIndicesToTagHstoreColumns < ActiveRecord::Migration
  def change
    add_index :current_routes, :tags
    add_index :current_stops, :tags
    add_index :current_operators, :tags
    add_index :feeds, :tags
  end
end
