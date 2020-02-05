# Local Instructions

These are instructions for how to run the Datastore application and its associated processes for local development. These are not instructions for how to set up your own hosted instance (which, anyways, is not the point of this centralized, community-run web "property").

## To Develop Locally

0. We'll assume you already have Ruby 2.0+ and Python 2.7 interpreters available on your system.

1. Install dependencies. Here's how to do it on Mac OS using the [Homebrew package manager](http://brew.sh/):

  * `brew install postgis` Postgres database with the [PostGIS extension](http://postgis.net/)
  * `brew install redis` [Redis key-value store](http://redis.io/) (used for the Sidekiq async worker queue)
  * **optional** `brew install graphviz` Graphviz graph visualization library (used to generate entity-relation diagrams). Only necessary if you'll be adding models and database migrations.

2. Run the Datastore setup script, which will install Ruby gems, install Python packages, and set your local configuration to default values:

    ````
    bin/setup
    ````

2. Depending upon your needs, you may need to modify your configuration by editing `config/application.yml` and `config/database.yml`.

   Note that any values in `config/database.yml` can also be overwritten with environment variables---useful if you're running a production server.

   The tokens you specify in `config/application.yml` will be used for [API Authentication](authentication.md#api).

3. Create and initialize the database:

  ````
  bundle exec rake db:create
  bundle exec rake db:structure:load
  ````

4. Start the server and background queue: `bundle exec foreman start`

5. If you're going to be coding, please read more about our [development practices](development-practices.md).

## To Run Tests Locally

1. Run the full test suite: `bundle exec rake`
2. To view coverage report: `open coverage/index.html`

## To Import Feeds Locally

First load feed and operator records from the sample changesets included in this repository: `bundle exec rake db:load:sample_changesets`

Now start the server and background queue and fetch feed files from their URLs:

1. `bundle exec rake enqueue_feed_fetcher_workers`
2. `bundle exec foreman`

After the feed files have been fetched, you can imported a feed:

- just the operator record from latest feed version: `bundle exec rake enqueue_feed_eater_worker[f-9q9-bart]`
- operator with stops and routes from latest feed version: `bundle exec rake enqueue_feed_eater_worker[f-9q9-bart,'',1]`
- operator with stops, routes, and schedules from latest feed version: `bundle exec rake enqueue_feed_eater_worker[f-9q9-bart,'',2]`
- operator with stops and routes from a specific feed version (include the SHA1 hash of the feed version): `bundle exec rake enqueue_feed_eater_worker[f-9q9-caltrain,'ab1e6ac73943082803f110df4b0fdd63a1d6b9f7',1]`

Alternatively, you can start the server and background queue and enqueue the workers using HTTP endpoints:

To fetch all feeds: `POST /api/v1/webhooks/feed_fetcher`

To import a feed:

- to import the latest feed version: `POST /api/v1/webhooks/feed_eater?feed_onestop_id=f-9q9-caltrain`
- to import a specific feed version: `POST /api/v1/webhooks/feed_eater?feed_onestop_id=f-9q9-caltrain&feed_version_sha1=ab1e6ac73943082803f110df4b0fdd63a1d6b9f7`

Note that these endpoint requires [API authentication](authentication.md#api).

To check the status of background workers, you can view Sidekiq's dashboard at: `/admin/sidekiq`. In production and staging environments, accessing the dashboard will require the user name and password specified in `/config/application.yml` or by environment variable.

To run the background workers regularly on servers, set up crontab entries:

    bundle exec whenever --update-crontab --set environment=production

Note that the crontab schedule is set in [config/schedule.rb](config/schedule.rb).

