class RemoveLatestFetchExceptionLogColumnFromFeed < ActiveRecord::Migration
  def change
    [:current, :old].each do |version|
      remove_column "#{version}_feeds", :latest_fetch_exception_log
    end
  end
end
