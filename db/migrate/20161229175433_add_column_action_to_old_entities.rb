class AddColumnActionToOldEntities < ActiveRecord::Migration
  def change
    [:feeds, :operators, :stops, :routes, :route_stop_patterns].each do |entity|
      add_column "old_#{entity}", :action, :string
    end
  end
end
