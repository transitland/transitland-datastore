class CreateStopTransfers < ActiveRecord::Migration
  def change
    [:current, :old].each do |version|
      create_table "#{version}_stop_transfers" do |t|
        t.string :connection_type, index: true
        t.hstore :tags
        t.references :stop, index: true
        t.references :origin, class_name: "Stop", index: true
        t.references :destination, class_name: "Stop", index: true
        t.references :created_or_updated_in_changeset #, index: true # TODO: short index name
        t.integer :version
        t.timestamps
      end
    end
  end
end
