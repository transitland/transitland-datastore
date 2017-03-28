class AddFeedvalidatorOutputToFeedVersion < ActiveRecord::Migration
  def change
    add_column :feed_versions, :file_feedvalidator, :string
  end
end
