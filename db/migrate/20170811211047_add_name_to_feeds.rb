class AddNameToFeeds < ActiveRecord::Migration
  def change
    [:current, :old].each do |version|
      change_table "#{version}_feeds" do |t|
        t.string :name,  index: true
      end
    end
  end
end
