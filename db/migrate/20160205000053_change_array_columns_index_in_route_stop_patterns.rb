class ChangeArrayColumnsIndexInRouteStopPatterns < ActiveRecord::Migration
  def change
    ["current","old"].each do |version|
      remove_index "#{version}_route_stop_patterns", :trips
      remove_index "#{version}_route_stop_patterns", :stop_pattern
      add_index "#{version}_route_stop_patterns", :trips, using: :gin
      add_index "#{version}_route_stop_patterns", :stop_pattern, using: :gin
    end
  end
end
