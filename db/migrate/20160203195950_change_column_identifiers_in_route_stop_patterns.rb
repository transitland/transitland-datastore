class ChangeColumnIdentifiersInRouteStopPatterns < ActiveRecord::Migration
  def change
    ["current","old"].each do |version|
      remove_column "#{version}_route_stop_patterns", :identifiers, array: true, index: true, default: []
      add_column "#{version}_route_stop_patterns", :identifiers, :string, array: true, index: true, default: [], using: :gin
    end
  end
end
