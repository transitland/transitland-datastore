class AddErrorToChangeset < ActiveRecord::Migration
  def change
    add_column :changesets, :error, :string
  end
end
