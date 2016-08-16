namespace :db do
  namespace :cleanup do
    desc 'Deleting entities belonging only to inactive feed versions ([0]: logging mode, [1]: delete mode).'
    task :cleanup_unreferenced_entities, [:mode] => [:environment] do |t, args|
      args.with_defaults(:mode => 0)
      mode = args[:mode].to_i
      puts mode == 0 ? "logging mode" : "delete mode"
      begin
        [Stop,Route,RouteStopPattern].each do |entity|
          entities_inactive = entity.where_inactive
          puts "Found #{entities_inactive.count} #{entity.to_s}s to delete."

          entities_inactive.find_in_batches do |entities_to_delete|

            # Delete entities
            entities_to_delete.each { |e| puts " #{entity.to_s}: #{e.onestop_id}" }
            if (mode == 1)
              puts "Deleting unreferenced #{entity.to_s}s."
              entities_to_delete.each { |e| e.delete }
            end

            # Delete EIFFs
            entities_imported = EntityImportedFromFeed.where(entity_id: entities_to_delete, entity_type: entity.to_s)
            puts "Found #{entities_imported.size} EntityImportedFromFeed #{entity.to_s}s to delete."
            if (mode == 1 && !entities_imported.empty?)
              puts "Deleting unreferenced EntityImportedFromFeed #{entity.to_s}s."
              entities_imported.delete_all
            end

            # Delete OSR / RSS
            if (entity == Route)
              route_serving_stops = RouteServingStop.where(route_id: entities_to_delete)
              puts "Found #{route_serving_stops.size} RouteServingStops to delete."
              if (mode == 1 && !route_serving_stops.empty?)
                puts "Deleting unreferenced RouteServingStops."
                route_serving_stops.delete_all
              end
            end

            if (entity == Stop)
              operator_serving_stops = OperatorServingStop.where(stop_id: entities_to_delete)
              puts "Found #{operator_serving_stops.size} OperatorServingStops to delete."
              if (mode == 1 && !operator_serving_stops.empty?)
                puts "Deleting unreferenced OperatorServingStops."
                operator_serving_stops.delete_all
              end
            end
          end
        end
      rescue
        puts "Error: #{$!.message}"
        puts $!.backtrace
      end
    end

    desc 'Deleting ScheduleStopPairs belonging only to inactive feed versions ([0]: logging mode, [1]: delete mode).'
    task :cleanup_unreferenced_ssps, [:mode] => [:environment] do |t, args|
      # TODO:
      # ScheduleStopPair.where(feed_version: FeedVersion.where.not(id: Feed.select(:active_feed_version_id)))
    end
  end
end
