#!/usr/bin/env puma
port        ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "development" }

preload_app!
on_worker_boot do
  ActiveRecord::Base.establish_connection
end
