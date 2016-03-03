namespace :db do
  namespace :cleanup do
    desc 'Deleting entities belonging only to inactive feed versions'
    task :cleanup_unreferenced_entities, [] => [:environment] do |t, args|
      begin
        [Stop,Route,RouteStopPattern,Operator].each do |entity|
          entities_to_delete = entity.where('').reject { |e| e.imported_from_feed_versions.any?(&:is_active_feed_version) }
          entities_to_delete_ids = entities_to_delete.map(&:id)
          if (entity == Route)
            RouteServingStop.where(route_id: entities_to_delete_ids).delete_all
          end
          if (entity == Operator)
            OperatorServingStop.where(operator_id: entities_to_delete_ids).delete_all
          end
          EntityImportedFromFeed.where(entity_id: entities_to_delete_ids).delete_all
          entities_to_delete.each { |e| e.delete }
        end
      rescue
        puts "Error: #{$!.message}"
        puts $!.backtrace
      end
    end
  end
end
