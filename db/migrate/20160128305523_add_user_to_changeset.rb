class AddUserToChangeset < ActiveRecord::Migration
  def change
    add_reference :changesets, :user, index: true
  end
end
