class AddUserToChangeset < ActiveRecord::Migration
  def change
    add_reference :changesets, :author, index: true
  end
end
