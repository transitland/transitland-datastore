class RemoveIsModifiedFromRouteStopPattern < ActiveRecord::Migration
  def change
    [:current, :old].each do |version|
      remove_column "#{version}_route_stop_patterns", :is_modified
    end
  end
end
