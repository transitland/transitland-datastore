PG_TIMEOUT = Figaro.env.pg_timeout || '120000' # milliseconds
ActiveRecord::Base.connection.execute("SET statement_timeout = '#{PG_TIMEOUT}'")
