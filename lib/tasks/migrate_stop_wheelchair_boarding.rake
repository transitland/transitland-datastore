namespace :db do
  namespace :migrate do
    task :migrate_stop_wheelchair_boarding, [] => [:environment] do |t, args|
      Stop.with_tag('wheelchair_boarding').find_each do |stop|
        old_value = stop.tags["wheelchair_boarding"]
        new_value = GTFSGraph.to_tfn(old_value)
        puts "#{stop.onestop_id} wheelchair_boarding: tag #{old_value} -> #{new_value}"
        stop.update_attribute(
          :wheelchair_boarding,
          new_value
        )
      end
    end
  end
end
