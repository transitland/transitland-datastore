class CreateFeedScheduleImports < ActiveRecord::Migration
  def change
    create_table :feed_schedule_imports do |t|
      t.boolean :success
      t.text :import_log
      t.text :exception_log
      t.references :feed_import, index: true

      t.timestamps null: false
    end
  end
end
