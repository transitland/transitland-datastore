class AddExceptionLogToFeedImport < ActiveRecord::Migration
  def change
    add_column :feed_imports, :exception_log, :text
  end
end
