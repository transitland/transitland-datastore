class OnlyOneCanonicalNamePerStop < ActiveRecord::Migration
  def change
    remove_column :stops, :codes
    add_column :stops, :name, :string
    Stop.find_each do |stop|
      stop.update(name: stop.names.first) if stop.names.count > 0
    end
    remove_column :stops, :names
  end
end
