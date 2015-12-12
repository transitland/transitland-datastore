class AddRouteReferenceToRouteStopPatterns < ActiveRecord::Migration
  def change
    add_reference :current_route_stop_patterns, :route, index: true, polymorphic: true
    add_reference :old_route_stop_patterns, :route, index: true, polymorphic: true
  end
end
