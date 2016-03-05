class AddColorToRoutes < ActiveRecord::Migration
  def change
    add_column :current_routes, :color, :string
    add_column :old_routes, :color, :string
    [Route, OldRoute].each do |route|
      route.find_each do |r|
         r.color = Route.color_from_gtfs(r.tags[:route_color])
         r.save!
      end
    end
  end
end
