# Administration Interface

Visit `/admin` to:

- reset the database
- use the [Transitland Dispatcher](https://github.com/transitland/dispatcher) interface to view, fetch, and load feeds
- view Sidekiq's dashboard
- view Postgres query performance (using [PgHero](https://github.com/ankane/pghero))

In production and staging environments, accessing the dashboard will require the user name and password specified in `/config/application.yml` or by environment variable.

On a local development machine, you'll need to run a separate copy of Transitland Dispatcher at `http://localhost:4200`. And if you want to analyze queries using PgHero, you'll need to [enable the pg_stat_statements module in your local Postgres server](https://github.com/ankane/pghero/blob/master/guides/Query-Stats.md).
