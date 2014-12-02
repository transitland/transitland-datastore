class AddOnestopIdToOperator < ActiveRecord::Migration
  def change
    add_column :operators, :onestop_id, :string
    add_index :operators, :onestop_id, unique: true
  end
end
