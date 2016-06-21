class RemoveExtraneousIndexes < ActiveRecord::Migration
  INDEXES_TO_REMOVE = [
    {
      table: :current_operators_serving_stop,
      column: :stop_id
    },
    {
      table: :current_schedule_stop_pairs,
      column: :feed_id
    },
    {
      table: :current_schedule_stop_pairs,
      column: :feed_version_id
    }
  ]

  def up
    INDEXES_TO_REMOVE.each do |hash|
      if index_exists?(hash[:table], hash[:column])
        remove_index(hash[:table], column: hash[:column])
      end
    end
  end

  def down
    INDEXES_TO_REMOVE.each do |hash|
      unless index_exists?(hash[:table], hash[:column])
        add_index(hash[:table], hash[:column])
      end
    end
  end
end
