class CreateFeedVersionInfos < ActiveRecord::Migration
  def change
    create_table :feed_version_infos do |t|
      t.string :type
      t.json :data
      t.references :feed_version, index: true
      t.timestamps
    end
  end
end
