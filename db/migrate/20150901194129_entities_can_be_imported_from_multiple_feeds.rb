class EntitiesCanBeImportedFromMultipleFeeds < ActiveRecord::Migration
  def change
    [:current, :old].each do |version|
      [:operators, :stops, :routes, :schedule_stop_pairs].each do |entity|
        remove_reference "#{version}_#{entity}", :feed
      end
    end

    create_table :entities_imported_from_feed do |t|
      t.references :entity, polymorphic: true, index: true
      t.references :feed, index: true
      t.timestamps
    end
  end
end
