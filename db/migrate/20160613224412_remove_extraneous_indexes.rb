class RemoveExtraneousIndexes < ActiveRecord::Migration
  def change
    remove_index :current_operators_serving_stop, name: :index_current_operators_serving_stop_on_stop_id
    remove_index :current_schedule_stop_pairs, name: :index_current_schedule_stop_pairs_on_feed_id
    remove_index :current_schedule_stop_pairs, name: :index_current_schedule_stop_pairs_on_feed_version_id
  end
end
