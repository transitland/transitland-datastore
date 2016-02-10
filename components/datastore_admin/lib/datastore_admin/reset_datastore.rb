module DatastoreAdmin
  class ResetDatastore
    require 'singleton'

    def self.clear_enqueued_jobs
      # NOTE: this just clears the default queue
      Sidekiq::Queue.new.clear
    end

    def self.destroy_feed_versions
      FeedVersion.find_each do |feed_version|
        feed_version.destroy
      end
    end

    def self.truncate_database
      # NOTE: don't truncate schema_migrations or spatial_ref_sys
      sql = "
        TRUNCATE changesets,
                 change_payloads,
                 current_feeds,
                 current_operators_in_feed,
                 current_operators,
                 current_operators_serving_stop,
                 current_routes,
                 current_routes_serving_stop,
                 current_stops,
                 current_schedule_stop_pairs,
                 current_route_stop_patterns,
                 old_schedule_stop_pairs,
                 feed_versions,
                 feed_version_imports,
                 feed_schedule_imports,
                 entities_imported_from_feed,
                 old_feeds,
                 old_operators_in_feed,
                 old_operators,
                 old_operators_serving_stop,
                 old_routes,
                 old_routes_serving_stop,
                 old_route_stop_patterns,
                 old_stops,
                 users;

        ALTER SEQUENCE changesets_id_seq RESTART;
        ALTER SEQUENCE change_payloads_id_seq RESTART;
        ALTER SEQUENCE current_feeds_id_seq RESTART;
        ALTER SEQUENCE current_operators_in_feed_id_seq RESTART;
        ALTER SEQUENCE current_operators_id_seq RESTART;
        ALTER SEQUENCE current_operators_serving_stop_id_seq RESTART;
        ALTER SEQUENCE current_routes_id_seq RESTART;
        ALTER SEQUENCE current_routes_serving_stop_id_seq RESTART;
        ALTER SEQUENCE current_stops_id_seq RESTART;
        ALTER SEQUENCE current_schedule_stop_pairs_id_seq RESTART;
        ALTER SEQUENCE current_route_stop_patterns_id_seq RESTART;
        ALTER SEQUENCE feed_versions_id_seq RESTART;
        ALTER SEQUENCE feed_version_imports_id_seq RESTART;
        ALTER SEQUENCE feed_schedule_imports_id_seq RESTART;
        ALTER SEQUENCE entities_imported_from_feed_id_seq RESTART;
        ALTER SEQUENCE old_feeds_id_seq RESTART;
        ALTER SEQUENCE old_operators_in_feed_id_seq RESTART;
        ALTER SEQUENCE old_operators_id_seq RESTART;
        ALTER SEQUENCE old_operators_serving_stop_id_seq RESTART;
        ALTER SEQUENCE old_routes_id_seq RESTART;
        ALTER SEQUENCE old_routes_serving_stop_id_seq RESTART;
        ALTER SEQUENCE old_stops_id_seq RESTART;
        ALTER SEQUENCE old_schedule_stop_pairs_id_seq RESTART;
        ALTER SEQUENCE old_route_stop_patterns_id_seq RESTART;
        ALTER SEQUENCE users_id_seq RESTART;
      "
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end
