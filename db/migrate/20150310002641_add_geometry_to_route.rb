class AddGeometryToRoute < ActiveRecord::Migration
  def change
    add_column :current_routes, :geometry, :geometry, geographic: true
    add_column :old_routes, :geometry, :geometry, geographic: true
  end
end
