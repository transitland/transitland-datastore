class AddUpdatedAtIndex < ActiveRecord::Migration
  def change
    add_index :current_operators, :updated_at
    add_index :current_routes, :updated_at
    add_index :current_stops, :updated_at
    add_index :current_schedule_stop_pairs, :updated_at
    # add_index :feeds, :updated_at
    # add_index :changesets, :updated_at
  end
end
