class AddAdditionalSspIndexes < ActiveRecord::Migration
  def change
    add_index :current_schedule_stop_pairs, [:feed_id, :id]
    add_index :current_schedule_stop_pairs, [:feed_version_id, :id]
  end
end
