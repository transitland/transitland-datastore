class RemovePayloadFromChangeset < ActiveRecord::Migration
  def change
    remove_column :changesets, :payload
  end
end
