class CreateStops < ActiveRecord::Migration
  def change
    create_table :stops do |t|
      t.string :onestop_id
      t.geometry :geometry, geographic: true
      t.string :codes, array: true
      t.string :names, array: true
      t.hstore :tags
      t.timestamps
    end
  end
end
