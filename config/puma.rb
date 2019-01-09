#!/usr/bin/env puma
port        ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "development" }

# Preload app
preload_app!

# Configure connections
on_worker_boot do
  ActiveRecord::Base.establish_connection

  PG_TIMEOUT = Figaro.env.pg_timeout || '120000' # milliseconds
  ActiveRecord::Base.connection.execute("SET statement_timeout = '#{PG_TIMEOUT}'")
end
