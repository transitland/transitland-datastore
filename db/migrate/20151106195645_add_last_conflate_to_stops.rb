class AddLastConflateToStops < ActiveRecord::Migration
  def change
    add_column :current_stops, :last_conflated_at, :datetime
    add_column :old_stops, :last_conflated_at, :datetime
  end
end
