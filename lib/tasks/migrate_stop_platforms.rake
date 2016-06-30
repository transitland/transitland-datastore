namespace :db do
  namespace :migrate do
    task :migrate_stop_platforms, [] => [:environment] do |t, args|
      Stop.with_tag('parent_station').find_each do |stop|
          parent_stop = Stop.find_by_onestop_id!(stop.tags.delete("parent_station"))
          stop.becomes(StopPlatform).update!(
            parent_stop: parent_stop,
            tags: stop.tags,
            type: 'StopPlatform'
          )
        end
    end
  end
end
