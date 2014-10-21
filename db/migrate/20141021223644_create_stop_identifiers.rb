class CreateStopIdentifiers < ActiveRecord::Migration
  def change
    create_table :stop_identifiers do |t|
      t.references :stop, index: true, null: false
      t.string :identifier_type
      t.string :identifier
      t.timestamps
    end
  end
end
