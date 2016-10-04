namespace :db do
  namespace :migrate do
    task :migrate_route_accessibility, [] => [:environment] do |t, args|
      Route.find_each do |route|
        ssps = ScheduleStopPair.select(:trip).select(:wheelchair_accessible).select(:bikes_allowed).where(route_id: route.id).uniq(:trip)

        wheelchair_result = :unknown
        if ssps.where(wheelchair_accessible: true).length == ssps.length
          wheelchair_result = :all_trips
        elsif ssps.where(wheelchair_accessible: true).length > 0
          wheelchair_result = :some_trips
        else
          if ssps.where(wheelchair_accessible: false) == ssps.length
            wheelchair_result = :no_trips
          end
        end

        bike_result = :unknown
        if ssps.where(bikes_allowed: true).length == ssps.length
          bike_result = :all_trips
        elsif ssps.where(bikes_allowed: true).length > 0
          bike_result = :some_trips
        else
          if ssps.where(bikes_allowed: false) == ssps.length
            bike_result = :no_trips
          end
        end

        puts "Updating Route #{route.onestop_id} wheelchair_accessible to #{wheelchair_result}"
        puts "Updating Route #{route.onestop_id} bikes_allowed to #{bike_result}"
        route.update(wheelchair_accessible: wheelchair_result, bikes_allowed: bike_result)
      end
    end
  end
end
