task :clear_enqueued_jobs, [] => [:environment] do |t, args|
  DatastoreAdmin::ResetDatastore.clear_enqueued_jobs
  puts "Cleared enqueued jobs."
  workers = Sidekiq::Workers.new
  if workers.size > 0
    puts "Note that #{workers.size} worker(s) are currently executing (and were not cleared)."
  end
end

task :truncate_database, [] => [:environment] do |t, args|
  DatastoreAdmin::ResetDatastore.truncate_database
  puts "Database has been truncated."
end

task :clear_data_directory, [] => [:environment] do |t, args|
  DatastoreAdmin::ResetDatastore.clear_data_directory
  puts "Data directory has been cleared."
end
