class AddAttributionTextToFeed < ActiveRecord::Migration
  def change
  	add_column :current_feeds, :license_attribution_text, :text
  	add_column :old_feeds, :license_attribution_text, :text
  end
end
