class CreateShapes < ActiveRecord::Migration
  def change
    create_table :current_shapes do |t|
      t.geometry :geometry, geographic: true
      t.hstore :tags

      t.timestamps null: false
    end

    create_table :old_shapes do |t|
      t.geometry :geometry, geographic: true
      t.hstore :tags

      t.timestamps null: false
    end
  end
end
