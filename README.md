[![Circle CI](https://circleci.com/gh/transitland/transitland-datastore.png?style=badge)](https://circleci.com/gh/transitland/transitland-datastore)
[![Dependency Status](https://gemnasium.com/transitland/transitland-datastore.svg)](https://gemnasium.com/transitland/transitland-datastore)

# Transitland Datastore

A community-run and -edited timetable and map of public transit service around the world.

Behind the scenes: a Ruby on Rails web service (backed by Postgres/PostGIS), along with an asynchronous Sidekiq queue (backed by Resque) that runs Ruby and Python data-ingestion libraries.

For more information about the overall process, see [Transitland: How it Works](http://transit.land/how-it-works/).

## Data Model

Every entity has a globally unique [Onestop ID](https://github.com/transitland/onestop-id-scheme). Entities include:

* `Feed`
* `Operator`
* `Stop`
* `Route`

The Datastore uses [changesets](doc/changesets.md) to track additions/edits/removals of entities.

Entities are associated with each other using relationship managers:

* [operator-route-stop relationships](doc/operator-route-stop-relationships.md)

Entities also include any number of [identifiers](doc/identifiers.md).

For a complete visualization of the Datastore's data model, see [doc/data-model.svg](doc/data-model.svg)

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

   The tokens you specify in `config/application.yml` will be used for [API Authentication](#api-authentication).

3. Create and initialize the database:

  ````
  bundle exec rake db:create
  bundle exec rake db:setup
  ````

4. **Optional** Add sample data to the database (includes [a few operators, stops, and routes in the SF Bay Area](db/sample-changesets/sf-bay-area.json)):

  ````
  bundle exec rake db:seed
  ````

5. Start the server and background queue: `bundle exec foreman start`

6. If you're going to be coding, please read more about our [development practices](doc/development-practices.md).

## To Run Tests Locally

1. Run the full test suite: `bundle exec rake`
2. To view coverage report: `open coverage/index.html`

## API Endpoints

Example URL  | Parameters
-------------|-----------
`GET /api/v1/changesets?applied=false` | changesets that have not yet been applied
`POST /api/v1/changesets` | include a [changeset payload](doc/changesets.md) in the request body
`PUT /api/v1/changesets/32`<br/>(a Changeset can only be updated if it hasn't yet been applied)| include a [changeset payload](doc/changesets.md) in the request body ([secured](#api-authentication))
`POST /api/v1/changesets/1/check` | ([secured](#api-authentication))
`POST /api/v1/changesets/1/apply` | ([secured](#api-authentication))
`POST /api/v1/changesets/1/revert` | ([secured](#api-authentication))
`DELETE /api/v1/changesets/1` | Delete Changeset ([secured](#api-authentication))
`GET /api/v1/changesets/1/change_payloads` |
`PUT /api/v1/changesets/1/change_payloads` | Add an additional [changeset payload](doc/changesets.md) to a Changeset ([secured](#api-authentication))
`POST /api/v1/changesets/1/change_payloads` |
`GET /api/v1/changesets/1/change_payloads/1` |
`PUT /api/v1/changesets/1/change_payloads/1` | ([secured](#api-authentication))
`DELETE /api/v1/changesets/1/change_payloads/1` | ([secured](#api-authentication))
`GET /api/v1/onestop_id/o-9q8y-SFMTA` | final part of the path can be a Onestop ID for any type of entity (for example, a stop or an operator)
`GET /api/v1/stops` | none required
`GET /api/v1/stops?identifier=4973` | `identifier` can be any type of stop identifier
`GET /api/v1/stops?identifier_starts_with=gtfs://f-9q9` | `identifier_starts_with` can be any type of stop identifier fragment
`GET /api/v1/stops?lon=-121.977772198&lat=37.413530093&r=100` | `lon` is longitude; `lat` is latitude; `r` is radius of search in meters (if not specified, defaults to 100 meters)
`GET /api/v1/stops?bbox=-122.4183,37.7758,-122.4120,37.7858` | `bbox` is a search bounding box with southwest longitude, southwest latitude, northeast longitude, northeast latitude (separated by commas)
`GET /api/v1/stops?servedBy=o-9q9-BART,r-9q8y-richmond~dalycity~millbrae` | `servedBy` can be any number of Onestop ID's for operators and routes
`GET /api/v1/stops?tag_key=wheelchair_boarding` | find all stops that have a tag of `tag_key` with any value
`GET /api/v1/stops?tag_key=wheelchair_boarding&tag_value=1` | find all stops that have a tag of `tag_key` and a value of `tag_value`
`GET /api/v1/operators` | none required
`GET /api/v1/operators?identifier=SFMUNI` | `identifier` can be any type of operator identifier
`GET /api/v1/operators?identifier_starts_with=gtfs://f-9q9` | `identifier_starts_with` can be any type of operator identifier fragment
`GET /api/v1/operators?lon=-121.977772198&lat=37.413530093&r=100` | `lon` is longitude; `lat` is latitude; `r` is radius of search in meters (if not specified, defaults to 100 meters)
`GET /api/v1/operators?bbox=-122.4183,37.7758,-122.4120,37.7858` | `bbox` is a search bounding box with southwest longitude, southwest latitude, northeast longitude, northeast latitude (separated by commas)
`GET /api/v1/operators?tag_key=agency_timezone` | find all operators that have a tag of `tag_key` with any value
`GET /api/v1/operators?tag_key=agency_timezone&tag_value=America/Los_Angeles` | find all operators that have a tag of `tag_key` and a value of `tag_value`
`GET /api/v1/routes` | none required
`GET /api/v1/routes?identifier=19X` | `identifier` can be any type of route identifier
`GET /api/v1/routes?identifier_starts_with=gtfs://f-9q9` | `identifier_starts_with` can be any type of route identifier fragment
`GET /api/v1/routes?operatedBy=o-9q9-BART` | `operatedBy` is a Onestop ID for an operator/agency
`GET /api/v1/routes?vehicle_type=bus,4` | find all routes with vehicle type(s) by integer or string. Possible values defined by the GTFS spec for [the `route_type` column](https://developers.google.com/transit/gtfs/reference#routes_route_type_field) and [the Extended GTFS Route Types](https://support.google.com/transitpartners/answer/3520902). Separate multiple vehicle types by commas.
`GET /api/v1/routes?bbox=-122.4183,37.7758,-122.4120,37.7858` | `bbox` is a search bounding box with southwest longitude, southwest latitude, northeast longitude, northeast latitude (separated by commas)
`GET /api/v1/routes?tag_key=route_color` | find all routes that have a tag of `tag_key` with any value
`GET /api/v1/routes?tag_key=route_color&tag_value=FEF0B5` | find all routes that have a tag of `tag_key` and a value of `tag_value`
`POST /api/v1/webhooks/feed_fetcher` | ([secured](#api-authentication)) fetches all feeds
`POST /api/v1/webhooks/feed_fetcher?feed_onestop_id=f-9q9-caltrain` | ([secured](#api-authentication)) fetches only one feed
`POST /api/v1/webhooks/feed_eater?feed_onestop_id=f-9q9-caltrain,feed_version_sha1=ab1e6ac73943082803f110df4b0fdd63a1d6b9f7` | ([secured](#api-authentication))
`GET /api/v1/feeds` | none required
`GET /api/v1/feeds?tag_key=license` | find all feeds that have a tag of `tag_key` with any value
`GET /api/v1/feeds?tag_key=license&tag_value=Creative%20Commons%20Attribution%203.0%20Unported%20License` | find all feeds that have a tag of `tag_key` and a value of `tag_value`
`GET /api/v1/feeds?bbox=-122.4183,37.7758,-122.4120,37.7858` | `bbox` is a search bounding box with southwest longitude, southwest latitude, northeast longitude, northeast latitude (separated by commas)
`GET /api/v1/feeds/f-9q9-bayarearapidtransit` | none required
`GET /api/v1/feeds/f-9q9-bayarearapidtransit/feed_versions` | none required
`GET /api/v1/feeds/f-9q9-bayarearapidtransit/feed_versions/c06b4b6b40815f27c81b4fcf486ac1fd70ab1966` | none required
`GET /api/v1/feeds/f-9q9-bayarearapidtransit/feed_versions/c06b4b6b40815f27c81b4fcf486ac1fd70ab1966/feed_version_imports` | none required
`GET /api/v1/feeds/f-9q9-bayarearapidtransit/feed_versions/c06b4b6b40815f27c81b4fcf486ac1fd70ab1966/feed_version_imports/1` | none required
`GET /api/v1/schedule_stop_pairs` | Find all [Schedule Stop Pairs](doc/schedule_api.md). All options below can be combined.
`GET /api/v1/schedule_stop_pairs?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation` | Find all Schedule Stop Pairs from origin. Accepts multiple Onestop IDs, separated by commas.
`GET /api/v1/schedule_stop_pairs?destination_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation` | Find all Schedule Stop Pairs to a destination. Accepts multiple Onestop IDs, separated by commas.
`GET /api/v1/schedule_stop_pairs?date=2015-08-05` | Find all Schedule Stop Pairs from origin on date
`GET /api/v1/schedule_stop_pairs?service_from_date=2015-08-05` | Find all Schedule Stop Pairs in effect from a date
`GET /api/v1/schedule_stop_pairs?service_before_date=2015-10-20` | Find all Schedule Stop Pairs in effect before a date
`GET /api/v1/schedule_stop_pairs?origin_departure_between=09:00:00,09:10:00` | Find all Schedule Stop Pairs with origin_departure_time in a range
`GET /api/v1/schedule_stop_pairs?trip=6507768-CT-14OCT-Combo-Weekday-01` | Find all Schedule Stop Pairs by trip identifier
`GET /api/v1/schedule_stop_pairs?route_onestop_id=r-9q8y-richmond~dalycity~millbrae` | Find all Schedule Stop Pairs by route. Accepts multiple Onestop IDs, separated by commas.
`GET /api/v1/schedule_stop_pairs?operator_onestop_id=o-9q9-caltrain` | Find all Schedule Stop Pairs by operator. Accepts multiple Onestop IDs, separated by commas.
`GET /api/v1/schedule_stop_pairs?bbox=-121.0,35.0,-124.0,37.0` | Find all Schedule Stop Pairs originating within a bounding box
`GET /api/v1/schedule_stop_pairs?active=true` | Schedule Stop Pairs from active FeedVersions
`GET /api/v1/schedule_stop_pairs?import_level=2` | Schedule Stop Pairs from FeedVersion with a given import_level


Pagination for JSON endpoints:
- `?offset=50` is the index of the first entity to be displayed (starts with 0)
- by default, 50 entities are displayed per page
- to show the total number of results, use `?total=true`

Format:
- by default, responses are paginated JSON
- specify `.geojson` instead for GeoJSON on some endpoints. For example: `/api/v1/stops.geojson?bbox=-122.4183,37.7758,-122.4120,37.7858` and `/api/v1/routes.geojson?operatedBy=o-9q9-bayarearapidtransit`

## Running the FeedEater pipeline

First load feed and operator records from the sample changesets included in this repository: `bundle exec rake db:load:sample_changesets` (***These files will be removed in the near future.***)

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

Note that these endpoint requires [API authentication](#api-authentication).

To check the status of background workers, you can view Sidekiq's dashboard at: `/admin/sidekiq`. In production and staging environments, accessing the dashboard will require the user name and password specified in `/config/application.yml` or by environment variable.

To run the background workers regularly on servers, set up crontab entries:

    bundle exec whenever --update-crontab --set environment=production

Note that the crontab schedule is set in [config/schedule.rb](config/schedule.rb).

## API Authentication

Any API calls that involve writing to the database (creating/editing/applying changesets or running the "feed eater" data ingestion pipeline) require authentication. API keys are specified in `config/application.yml`. The key can be any alphanumeric string. For example:

````yaml
# config/application.yml
TRANSITLAND_DATASTORE_AUTH_TOKEN: 1a4494f1fc463ab8e32d6b
````

Or, specify as an environment variable. For example, `TRANSITLAND_DATASTORE_AUTH_TOKEN: 1a4494f1fc463ab8e32d6b bundle exec rails server`

To authenticate, include the following in your POST or PUT request:

header name   | header value
------------- | ---------------------------------
Authorization | Token token=fde67e1437ebf73e1f3eW

## Conflating Stops with OpenStreetMap

Depends on the Valhalla routing engine and its [Tyr ("Take Your Route") service](https://github.com/valhalla/tyr/).

To automatically conflate stops whenever they are created or their location changed, add `TYR_AUTH_TOKEN` to `config/application.yml` and set `AUTO_CONFLATE_STOPS_WITH_OSM` to `true`.

## Administration Interface

Visit `/admin` to:

- reset the database
- use the [Transitland Dispatcher](https://github.com/transitland/dispatcher) interface to view, fetch, and load feeds
- view Sidekiq's dashboard
- view Postgres query performance (using [PgHero](https://github.com/ankane/pghero))

In production and staging environments, accessing the dashboard will require the user name and password specified in `/config/application.yml` or by environment variable.

On a local development machine, you'll need to run a separate copy of Transitland Dispatcher at `http://localhost:4200`. And if you want to analyze queries using PgHero, you'll need to [enable the pg_stat_statements module in your local Postgres server](https://github.com/ankane/pghero/blob/master/guides/Query-Stats.md).
