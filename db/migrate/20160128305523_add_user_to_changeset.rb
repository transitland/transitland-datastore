class AddUserToChangeset < ActiveRecord::Migration
  def change
    add_column :changesets, :author_email, :string
    add_index :changesets, :author_email
  end
end
