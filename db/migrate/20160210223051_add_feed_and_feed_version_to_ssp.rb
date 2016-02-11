class AddFeedAndFeedVersionToSsp < ActiveRecord::Migration
  def change
    ["current","old"].each do |version|
      add_reference "#{version}_schedule_stop_pairs", :feed, index: true
      add_reference "#{version}_schedule_stop_pairs", :feed_version, index: true
      remove_column "#{version}_schedule_stop_pairs", :active
    end
  end
end
