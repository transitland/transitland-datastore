class AssociateEntitiesWithFeeds < ActiveRecord::Migration
  def change
    [:current, :old].each do |version|
      [:operators, :stops, :routes, :schedule_stop_pairs].each do |entity|
        add_reference "#{version}_#{entity}", :feed, index: true
      end
    end
  end
end
