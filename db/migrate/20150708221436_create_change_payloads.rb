class CreateChangePayloads < ActiveRecord::Migration
  def change
    create_table :change_payloads do |t|
      t.json :payload
      t.references :changeset, index: true, foreign_key: true
      t.string :action
      t.string :type

      t.timestamps null: false
    end
  end
end
