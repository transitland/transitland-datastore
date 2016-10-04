class AddOnestopIdUniqueConstraint < ActiveRecord::Migration
  def change
    [Stop, Route, RouteStopPattern, Feed, Operator].each do |model|
      remove_index model.table_name, :onestop_id if index_exists?(model.table_name, :onestop_id)
      add_index model.table_name, :onestop_id, unique: true
    end
  end
end
