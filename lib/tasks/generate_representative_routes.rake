namespace :db do
  namespace :compute do
    task :representative_routes, [:mode] => [:environment] do |t, args|
      Route.find_each do |route|
        puts "Route #{route.onestop} coordinate size before: #{route.geometry[:coordinates].flatten.size/2.0}"
        representative_rsps = Route.representative_geometry(route, route.route_stop_patterns)
        puts "Route #{route.onestop_id} no. of representative rsps. Was: #{route.route_stop_patterns.size}, Now: #{representative_rsps.size}"
        Route.geometry_from_rsps(route, representative_rsps)
        puts "Route #{route.onestop} coordinate size after: #{route.geometry[:coordinates].flatten.size/2.0}"
        route.save!
      end
    end
  end
end
