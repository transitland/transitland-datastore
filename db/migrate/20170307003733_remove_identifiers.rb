class RemoveIdentifiers < ActiveRecord::Migration
  def change
    [:operators, :stops, :routes, :route_stop_patterns].each do |entity|
      [:current, :old].each do |version|
        remove_column "#{version}_#{entity}", :identifiers
      end
    end
  end
end
