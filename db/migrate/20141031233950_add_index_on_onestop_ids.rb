class AddIndexOnOnestopIds < ActiveRecord::Migration
  def change
    add_index :stops, :onestop_id
  end
end
