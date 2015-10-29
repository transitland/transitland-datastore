class AddLatestFetchLogToFeed < ActiveRecord::Migration
  def change
    [:current, :old].each do |version|
      add_column "#{version}_feeds", :latest_fetch_exception_log, :text
    end
  end
end
