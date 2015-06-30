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
                 current_operators,
                 current_operators_serving_stop,
                 current_routes,
                 current_routes_serving_stop,
                 current_stops,
                 feed_imports,
                 feeds,
                 old_operators,
                 old_operators_serving_stop,
                 old_routes,
                 old_routes_serving_stop,
                 old_stops;

        ALTER SEQUENCE changesets_id_seq RESTART;
        ALTER SEQUENCE current_operators_id_seq RESTART;
        ALTER SEQUENCE current_operators_serving_stop_id_seq RESTART;
        ALTER SEQUENCE current_routes_id_seq RESTART;
        ALTER SEQUENCE current_routes_serving_stop_id_seq RESTART;
        ALTER SEQUENCE current_stops_id_seq RESTART;
        ALTER SEQUENCE feed_imports_id_seq RESTART;
        ALTER SEQUENCE feeds_id_seq RESTART;
        ALTER SEQUENCE old_operators_id_seq RESTART;
        ALTER SEQUENCE old_operators_serving_stop_id_seq RESTART;
        ALTER SEQUENCE old_routes_id_seq RESTART;
        ALTER SEQUENCE old_routes_serving_stop_id_seq RESTART;
        ALTER SEQUENCE old_stops_id_seq RESTART;
      "
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end
