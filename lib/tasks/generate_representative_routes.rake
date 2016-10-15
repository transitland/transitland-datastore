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
          rsp = key_value[1].first
          representative_rsps.add(rsp)

          stop_pairs_to_rsps.each_pair { |key_pair, rsps|
            stop_pairs_to_rsps.delete(key_pair) if rsps.include?(rsp)
          }
        end
        
      end
    end
  end
end
