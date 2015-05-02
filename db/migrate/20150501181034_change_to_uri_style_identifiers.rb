class ChangeToUriStyleIdentifiers < ActiveRecord::Migration
  def change
    drop_table :current_identifiers
    drop_table :old_identifiers
    add_uri_style_identifiers('stops')
    add_uri_style_identifiers('operators')
    add_uri_style_identifiers('routes')
  end

  def add_uri_style_identifiers(table)
    add_column "current_#{table}", :identifiers, :string, array: true, default: []
    add_index "current_#{table}", :identifiers, using: :gin
    add_column "old_#{table}", :identifiers, :string, array: true, default: []
    add_index "old_#{table}", :identifiers, using: :gin
  end
end
