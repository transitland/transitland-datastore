class AddCurrentIdToOldRsp < ActiveRecord::Migration
  def change
    add_column "old_route_stop_patterns", :current_id, :integer
    add_index  "old_route_stop_patterns", :current_id
  end
end
