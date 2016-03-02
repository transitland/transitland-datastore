namespace :db do
  namespace :cleanup do
    desc 'Deleting entities belonging only to inactive feed versions'
    task :cleanup_entities, [] => [:environment] do |t, args|
      begin
        [Stop,Route,RouteStopPattern,Operator].each do |entity|
          imported_entities = EntityImportedFromFeed.select(:entity_id)
            .where.not(feed_version_id: Feed.select(:active_feed_version_id))
            .where(entity_type: entity.to_s)
          entity.where(id: imported_entities).delete_all
          if (entity == Route)
            RouteServingStop.where(route_id: imported_entities.uniq).delete_all
          end
          if (entity == Operator)
            OperatorServingStop.where(operator_id: imported_entities.uniq).delete_all
          end
          imported_entities.delete_all
        end
        # old tables?
      rescue
        puts "Error: #{$!.message}"
        puts $!.backtrace
      end
    end
  end
end
