namespace :db do
  namespace :compute do
    task :representative_routes, [:mode] => [:environment] do |t, args|
      stop_pairs_to_rsps = {}
      Route.find_each do |route|
        route.route_stop_patterns.each do |rsp|
          rsp.stop_pattern.each_cons(2) do |s1, s2|
            if stop_pairs_to_rsps.has_key?([s1,s2])
              stop_pairs_to_rsps[[s1,s2]].add(rsp.onestop_id)
            else
              stop_pairs_to_rsps[[s1,s2]] = Set.new([rsp.onestop_id])
            end
          end
        end

        representative_rsps = Set.new

        while (!stop_pairs_to_rsps.empty?)
          key_value = stop_pairs_to_rsps.shift
          rsp = key_value[1].max_by { |rsp_onestop_id|
            RouteStopPattern.find_by_onestop_id!(rsp_onestop_id).stop_pattern.uniq.size
          }
          representative_rsps.add(rsp)

          stop_pairs_to_rsps.each_pair { |key_pair, rsps|
            stop_pairs_to_rsps.delete(key_pair) if rsps.include?(rsp)
          }
        end

        puts "Route #{route.onestop_id} representative rsps. Was: #{route.route_stop_patterns.size}, Now: #{representative_rsps.size}"

        route.geometry = Route::GEOFACTORY.multi_line_string(
          (representative_rsps || []).map { |rsp|
            rsp = RouteStopPattern.find_by_onestop_id!(rsp)
            Route::GEOFACTORY.line_string(
              rsp.geometry[:coordinates].map { |lon, lat| Route::GEOFACTORY.point(lon, lat) }
            )
          }
        )
        route.save!
      end
    end
  end
end
