class AddGeometryToOperator < ActiveRecord::Migration
  def change
    add_column :operators, :geometry, :geometry, geographic: true
  end
end
