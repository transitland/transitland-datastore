class AddIndicesToGeometryColumns < ActiveRecord::Migration
  def change
    [:current, :old].each do |version|
      [:feeds, :operators, :stops, :routes].each do |entity|
        add_index "#{version}_#{entity}", :geometry, using: :gist
      end
    end
  end
end
