class AddEditedAttributesToEntity < ActiveRecord::Migration
  def change
    [Feed, FeedVersion, Operator, Route, Stop, RouteStopPattern].each do |entity|
      add_column entity.table_name, :edited_attributes, :string, array: true, default: []
    end
  end
end
