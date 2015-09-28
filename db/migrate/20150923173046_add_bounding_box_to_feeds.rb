class AddBoundingBoxToFeeds < ActiveRecord::Migration
  def change
    [:current_feeds, :old_feeds].each do |table|
      add_column table, :geometry, :geometry, geographic: true
    end
  end
end
