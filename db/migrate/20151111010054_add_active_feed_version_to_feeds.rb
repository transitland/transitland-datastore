class AddActiveFeedVersionToFeeds < ActiveRecord::Migration
  def change
    [:current, :old].each do |version|
      add_reference "#{version}_feeds", :active_feed_version
    end
  end
end
