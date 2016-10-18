namespace :db do
  namespace :compute do
    task :representative_routes, [:mode] => [:environment] do |t, args|
      Route.find_each do |route|
        representative_rsps = Route.representative_geometry(route, route.route_stop_patterns)
        puts "Route #{route.onestop_id} representative rsp count. Total: #{route.route_stop_patterns.size}, Representative: #{representative_rsps.size}"
        Route.geometry_from_rsps(route, representative_rsps)
        puts "Route #{route.onestop_id} total coordinate size: #{((representative_rsps.map { |rsp| rsp.geometry[:coordinates] }.flatten.size) / 2.0).to_i }"
        puts "Route #{route.onestop_id} representative coordinate size: #{ ((route.geometry[:coordinates].flatten.size) / 2.0).to_i }"
        route.save!
      end
    end
  end
end
