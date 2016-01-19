class CreateStations < ActiveRecord::Migration
  def change
    [:current, :old].each do |version|
      change_table "#{version}_stops" do |t|
        t.string :type
        t.references :parent_stop, references: :stops, index: true
      end
    end
  end
end
