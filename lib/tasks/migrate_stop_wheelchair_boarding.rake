task :migrate_stop_wheelchair_boarding do
  Stop.with_tag('wheelchair_boarding').find_each do |stop|
    stop.update_attribute(:wheelchair_boarding, AllowFiltering.to_boolean(stop.tags[:wheelchair_boarding]))
  end
end
