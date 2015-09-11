module DatastoreAdmin
  class ResetDatastore
    require 'singleton'

    def self.clear_enqueued_jobs
      # NOTE: this just clears the default queue
      Sidekiq::Queue.new.clear
    end

    def self.truncate_database
      # NOTE: don't truncate schema_migrations or spatial_ref_sys
      sql = "
        TRUNCATE changesets,
                 change_payloads,
                 current_operators,
                 current_operators_serving_stop,
                 current_routes,
                 current_routes_serving_stop,
                 current_stops,
                 current_schedule_stop_pairs,
                 old_schedule_stop_pairs,
                 feed_imports,
                 feeds,
                 entities_imported_from_feed,
                 old_operators,
                 old_operators_serving_stop,
                 old_routes,
                 old_routes_serving_stop,
                 old_stops;

        ALTER SEQUENCE changesets_id_seq RESTART;
        ALTER SEQUENCE change_payloads_id_seq RESTART;
        ALTER SEQUENCE current_operators_id_seq RESTART;
        ALTER SEQUENCE current_operators_serving_stop_id_seq RESTART;
        ALTER SEQUENCE current_routes_id_seq RESTART;
        ALTER SEQUENCE current_routes_serving_stop_id_seq RESTART;
        ALTER SEQUENCE current_stops_id_seq RESTART;
        ALTER SEQUENCE current_schedule_stop_pairs_id_seq RESTART;
        ALTER SEQUENCE feed_imports_id_seq RESTART;
        ALTER SEQUENCE feeds_id_seq RESTART;
        ALTER SEQUENCE entities_imported_from_feed_id_seq RESTART;
        ALTER SEQUENCE old_operators_id_seq RESTART;
        ALTER SEQUENCE old_operators_serving_stop_id_seq RESTART;
        ALTER SEQUENCE old_routes_id_seq RESTART;
        ALTER SEQUENCE old_routes_serving_stop_id_seq RESTART;
        ALTER SEQUENCE old_stops_id_seq RESTART;
        ALTER SEQUENCE old_schedule_stop_pairs_id_seq RESTART;
      "
      ActiveRecord::Base.connection.execute(sql)
    end

    def self.clear_data_directory
      FileUtils.rm_rf Dir.glob("#{Figaro.env.transitland_feed_data_path}/*")
    end
  end
end
