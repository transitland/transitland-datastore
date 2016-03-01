namespace :db do
  namespace :cleanup do
    desc 'Deleting entities belonging only to inactive feed versions'
    task :cleanup_entities, [] => [:environment] do |t, args|
      begin
        #EntityImportedFromFeed.includes(:feed_version).all.each do |eifv|
        #  eifv.entity_type
        #end
        #[RouteStopPattern, Stop, Route, Operator, OperatorServingStop, RouteServingStop].each do |entity|
        #  entity.where('').select { |obj| obj.imported_from_feed_versions.any?(&:is_active_feed_version) }.each do |o|
        #    o.destroy
        #  end
        #end
      rescue
        puts "Error: #{$!.message}"
        puts $!.backtrace
      end
    end
  end
end
