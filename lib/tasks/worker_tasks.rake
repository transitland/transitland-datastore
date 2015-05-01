task enqueue_feed_eater_worker: [:environment] do
  begin
    feed_eater_worker = FeedEaterWorker.perform_async
    if feed_eater_worker
      puts "FeedEaterWorker ##{feed_eater_worker} has been created and enqueued."
    else
      raise 'FeedEaterWorker could not be created or enqueued.'
    end
  rescue
    puts "Error: #{$!.message}"
    puts $!.backtrace
  end
end
