class CreateStopTransfers < ActiveRecord::Migration
  def change
    [:current, :old].each do |version|
      create_table "#{version}_stop_transfers" do |t|
        t.string :transfer_type, index: true
        t.integer :min_transfer_time, index: true
        t.hstore :tags
        t.references :stop, index: true
        t.references :to_stop, class_name: "Stop", index: true
        t.references :created_or_updated_in_changeset, index: { name: "index_#{version}_stop_transfers_changeset_id" }
        t.integer :version
        t.timestamps
      end
    end
    add_reference :old_stop_transfers, :destroyed_in_changeset, index: true
    add_reference :old_stop_transfers, :current, index: true
  end
end
