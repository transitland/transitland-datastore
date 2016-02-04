class ChangeColumnIdentifiersIndexInRouteStopPatterns < ActiveRecord::Migration
  def change
    ["current","old"].each do |version|
      remove_index "#{version}_route_stop_patterns", :identifiers
      add_index "#{version}_route_stop_patterns", :identifiers, using: :gin
    end
  end
end
