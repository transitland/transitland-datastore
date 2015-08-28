class ChangeOperatorsInFeedToArrayOfHstores < ActiveRecord::Migration
  def change
    remove_column :feeds, :operator_onestop_ids_in_feed
    add_column :feeds, :operators_in_feed, :hstore, array: true
  end
end
