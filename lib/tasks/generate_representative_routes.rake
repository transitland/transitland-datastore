namespace :db do
  namespace :compute do
    task :representative_routes, [:mode] => [:environment] do |t, args|
      Route.find_each do |route|
        representative_rsps = Route.representative_geometry(route, route.route_stop_patterns)

        puts "Route #{route.onestop_id} representative rsps. Was: #{route.route_stop_patterns.size}, Now: #{representative_rsps.size}"

        Route.geometry_from_rsps(route, representative_rsps)
        route.save!
      end
    end
  end
end
