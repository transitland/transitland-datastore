class AddAltGeometryToStops < ActiveRecord::Migration
  def change
    [:current, :old].each do |version|
      change_table "#{version}_stops" do |t|
        t.st_point :geometry_reversegeo, geographic: true, index: true
        t.index :geometry_reversegeo, using: :gist
      end
    end
  end
end
