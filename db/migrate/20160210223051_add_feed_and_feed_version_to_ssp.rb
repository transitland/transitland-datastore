class AddFeedAndFeedVersionToSsp < ActiveRecord::Migration
  def change
    ["current","old"].each do |version|
      add_reference "#{version}_schedule_stop_pairs", :feed, index: true
      add_reference "#{version}_schedule_stop_pairs", :feed_version, index: true
    end
  end
end
