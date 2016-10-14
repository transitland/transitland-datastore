class AddEditedAttributesToEntity < ActiveRecord::Migration
  def change
    [Feed, Operator, Route, Stop, RouteStopPattern].each do |entity|
      add_column entity.table_name, :edited_attributes, :string, array: true, default: []
      add_column entity.table_name.gsub('current', 'old'), :edited_attributes, :string, array: true, default: []
    end
  end
end
