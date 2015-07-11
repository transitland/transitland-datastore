class RemoveUnusedActionAndTypeColumnsFromChangePayload < ActiveRecord::Migration
  def change
    remove_column :change_payloads, :action
    remove_column :change_payloads, :type    
  end
end
