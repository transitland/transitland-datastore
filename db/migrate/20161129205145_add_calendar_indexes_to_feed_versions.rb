class AddCalendarIndexesToFeedVersions < ActiveRecord::Migration
  def change
    add_index :feed_versions, :earliest_calendar_date
    add_index :feed_versions, :latest_calendar_date
  end
end
