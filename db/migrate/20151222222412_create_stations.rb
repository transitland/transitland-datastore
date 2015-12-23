class CreateStations < ActiveRecord::Migration
  def change
    [:current, :old].each do |version|
      create_table "#{version}_stations" do |t|
        t.string :type
        t.string :onestop_id
        t.string :name
        t.datetime :last_conflated_at
        t.hstore :tags
        t.geometry :geometry, geographic: true
        t.references :parent_station, references: :stations, index: true # { name: "index_#{version}_station" }
        t.references :created_or_updated_in_changeset, index: { name: "index_#{version}_station_on_cu_in_changeset_id" }
        t.integer :version
        t.timestamps null: false
      end
      change_table "#{version}_stops" do |t|
        t.string :identifier
        t.string :url
        t.string :zone
        t.string :code
        t.string :description
        t.integer :wheelchair_boarding
        t.integer :location_type
        t.remove :tags
        t.remove :onestop_id
        t.remove :identifiers
        t.references :station, index: true
        t.references :parent_stop, references: :stops, index: true
      end
    end
  end
end
