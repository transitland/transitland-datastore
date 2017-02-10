namespace :feed do
  namespace :debug do
    task :rename_feed_version_attachments, [:feed_onestop_ids] => [:environment] do |t, args|
      args.with_defaults(feed_onestop_ids: nil)
      feeds = Feed.where('')
      if args.feed_onestop_ids
        feeds = Feed.find_by_onestop_ids!(args.feed_onestop_ids.split(","))
      end
      feeds.each do |feed|
        feed.feed_versions.each do |feed_version|
          begin
            feed_version.file = File.open(feed_version.file.local_path_copying_locally_if_needed) if feed_version.file.url
            feed_version.file_raw = File.open(feed_version.file_raw.local_path_copying_locally_if_needed) if feed_version.file_raw.url
            feed_version.file_feedvalidator = File.open(feed_version.file_feedvalidator.local_path_copying_locally_if_needed) if feed_version.file_feedvalidator.url
            feed_version.save!
            feed_version.file.remove_any_local_cached_copies
            feed_version.file_raw.remove_any_local_cached_copies
            feed_version.file_feedvalidator.remove_any_local_cached_copies
            puts "Updated: #{feed_version.sha1}"
          rescue
            puts "Could not update: #{feed_version.sha1}"
          end
        end
      end
    end
  end
end
