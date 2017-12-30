#!/usr/bin/env puma
bind 'tcp://0.0.0.0:3000'
environment ENV.fetch("RAILS_ENV") { "development" }
