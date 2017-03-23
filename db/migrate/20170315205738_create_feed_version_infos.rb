class CreateFeedVersionInfos < ActiveRecord::Migration
  def change
    create_table :feed_version_infos do |t|
      t.json :statistics
      t.json :scheduled_service
      t.string :filenames, array: true
      t.references :feed_version, index: true
      t.timestamps
    end
  end
end
