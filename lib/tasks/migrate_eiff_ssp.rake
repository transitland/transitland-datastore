ActiveRecord::Base.logger = Logger.new(STDOUT)

namespace :db do
  namespace :migrate do
    task :migrate_eiff_ssp, [] => [:environment] do |t, args|

      # find_in_batches works by 'table.id > last_id', so should be safe to
      # delete at the end of a find_in_batches block.
      total = EntityImportedFromFeed.where(entity_type: 'ScheduleStopPair').count
      EntityImportedFromFeed
        .where(entity_type: 'ScheduleStopPair')
        .select("id, entity_id, feed_id, feed_version_id")
        .find_in_batches do |eiffs|
          puts "Processing EIFFS #{eiffs.first.id} - #{eiffs.last.id} / #{total}"
          # Update each SSP with Feed and FeedVersion
          eiffs.each do |eiff|
            ScheduleStopPair
              .find(eiff.entity_id)
              .update_columns(feed_id: eiff.feed_id, feed_version_id: eiff.feed_version_id)
          end
          # Bulk delete EIFFs; also permits restarting process
          EntityImportedFromFeed.delete(eiffs)
        end

    end
  end
end
