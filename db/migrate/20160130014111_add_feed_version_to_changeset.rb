class AddFeedVersionToChangeset < ActiveRecord::Migration
  def change
    add_reference :changesets, :feed, index: true
    add_reference :changesets, :feed_version, index: true
  end
end
