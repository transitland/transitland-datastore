class AddDirectionalityToStopEgress < ActiveRecord::Migration
  def change
    add_column :current_stops, :directionality, :integer
    add_column :old_stops, :directionality, :integer
  end
end
