class OnlyOneCanonicalNamePerStop < ActiveRecord::Migration
  class Stop < ActiveRecord::Base
    # psuedo object stand-in, since new versions of code have Stop and OldStop
  end

  def change
    remove_column :stops, :codes
    add_column :stops, :name, :string
    Stop.find_each do |stop|
      stop.update(name: stop.names.first) if stop.names.count > 0
    end
    remove_column :stops, :names
  end
end
