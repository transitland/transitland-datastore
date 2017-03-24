class CreateFeedVersionInfos < ActiveRecord::Migration
  def change
    create_table :feed_version_infos do |t|
      t.string :type
      t.json :data
      t.references :feed_version, index: true
      t.timestamps
    end
    add_index :feed_version_infos, [:feed_version_id, :type], unique: true
  end
end
