class CreateOperatorAndOperatorServingStop < ActiveRecord::Migration
  def change
    create_table :operators do |t|
      t.string :name
      t.hstore :tags
      t.timestamps
    end

    create_table :operator_serving_stops do |t|
      t.references :stop, index: true, null: false
      t.references :operator, index: true, null: false
      t.hstore :tags
      t.timestamps
    end
    add_index :operator_serving_stops, [:stop_id, :operator_id], unique: true
  end
end
