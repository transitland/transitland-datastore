class RenameToOperatorsServingStop < ActiveRecord::Migration
  def change
    rename_table :operator_serving_stops, :operators_serving_stop
  end
end
