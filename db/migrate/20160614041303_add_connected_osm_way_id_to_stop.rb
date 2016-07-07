class AddConnectedOsmWayIdToStop < ActiveRecord::Migration
  def change
    [:current, :old].each do |version|
      add_column "#{version}_stops", :osm_way_id, :integer
    end
  end
end
