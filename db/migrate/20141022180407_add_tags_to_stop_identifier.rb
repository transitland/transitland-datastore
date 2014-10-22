class AddTagsToStopIdentifier < ActiveRecord::Migration
  def change
    remove_column :stop_identifiers, :identifier_type
    add_column :stop_identifiers, :tags, :hstore
  end
end
