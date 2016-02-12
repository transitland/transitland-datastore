ActiveRecord::Base.logger = Logger.new(STDOUT)

namespace :db do
  namespace :migrate do
    task :migrate_eiff_ssp, [] => [:environment] do |t, args|
      last_ssp = ScheduleStopPair.last.id
      current_ssp = 0
      batch_size = 100_000
      while current_ssp < last_ssp do
        query = <<-EOQ
          UPDATE current_schedule_stop_pairs AS ssp
          SET feed_id = eiff.feed_id, feed_version_id = eiff.feed_version_id
          FROM entities_imported_from_feed AS eiff
          WHERE
            ssp.id = eiff.entity_id AND
            ssp.id >= #{current_ssp} AND
            ssp.id < #{current_ssp + batch_size} AND
            eiff.entity_type = 'ScheduleStopPair'
        EOQ
        st = ActiveRecord::Base.connection.execute(query)
        current_ssp += batch_size
      end
      # Delete EIFFs in batches; find_in_batches keeps track of last ID.
      EntityImportedFromFeed
        .where(entity_type: 'ScheduleStopPair')
        .select('id')
        .find_in_batches do |eiffs|
          EntityImportedFromFeed.delete(eiffs)
        end
      # Done
    end
  end
end
