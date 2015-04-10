[![Circle CI](https://circleci.com/gh/transitland/transitland-datastore.png?style=badge)](https://circleci.com/gh/transitland/transitland-datastore)
[![Dependency Status](https://gemnasium.com/transitland/transitland-datastore.svg)](https://gemnasium.com/transitland/transitland-datastore)

# Transitland Datastore

A community-run and -edited timetable and map of public transit service around the world.

Integrates with the [Onestop ID Registry](https://github.com/transitland/onestop-id-registry).

Behind the scenes: a Ruby on Rails web service, backed by Postgres/PostGIS.

## Data Model

![diagram of Transitland Datastore's data model](https://rawgit.com/transitland/transitland-datastore/master/doc/data-model.svg)

The Datastore uses [changesets](doc/changesets.md) to track additions/edits/removals of entities.

Every entity has a globally unique Onestop ID (from the [Onestop ID Registry](https://github.com/transit-land/onestop-id-registry)). Entities include:

* `Operator`
* `Stop`
* `Route`

Entities are associated with each other using relationship managers:

* [operator-route-stop relationships](doc/operator-route-stop-relationships.md)

## To Develop Locally

1. Install dependencies:

    ````
    brew install postgis
    brew install redis
    brew install graphviz
    bundle install
    ````

2. Configure your local copy by renaming the example files to `config/application.yml` and `config/database.yml`. Edit as appropriate.

3. Create and initialize the database:

  ````
  bundle exec rake db:create
  bundle exec rake db:setup
  ````

4. Start the server: `bundle exec rails server`

## To Run Tests Locally

1. Install dependencies: `brew install chromedriver` (as well as a copy of the latest Chrome)
2. Run the full test suite: `bundle exec rake`
3. To view coverage report: `open coverage/index.html`

## API Endpoints

Example URL  | Parameters
-------------|-----------
`POST /api/v1/changesets` | include a [changeset payload](doc/changesets.md) in the request body
`PUT /api/v1/changesets/32`<br/>(a Changeset can only be updated if it hasn't yet been applied)| include a [changeset payload](doc/changesets.md) in the request body
`POST /api/v1/changesets/1/check` | 
`POST /api/v1/changesets/1/apply` | 
`POST /api/v1/changesets/1/revert` | 
`GET /api/v1/onestop_id/o-9q8y-SFMTA` | final part of the path can be a Onestop ID for any type of entity (for example, a stop or an operator)
`GET /api/v1/stops` | none required
`GET /api/v1/stops?identifer=4973` | `identifier` can be any type of stop identifier
`GET /api/v1/stops?lon=-121.977772198&lat=37.413530093&r=100` | `lon` is longitude; `lat` is latitude; `r` is radius of search in meters (if not specified, defaults to 100 meters)
`GET /api/v1/stops?bbox=-122.4183,37.7758,-122.4120,37.7858` | `bbox` is a search bounding box with southwest longitude, southwest latitude, northeast longitude, northeast latitude (separated by commas)
`GET /api/v1/stops?servedBy=o-9q9-BART,r-9q8y-richmond~dalycity~millbrae` | `servedBy` can be any number of Onestop ID's for operators and routes
`GET /api/v1/operators` | none required
`GET /api/v1/operators?identifer=SFMUNI` | `identifier` can be any type of operator identifier
`GET /api/v1/operators?lon=-121.977772198&lat=37.413530093&r=100` | `lon` is longitude; `lat` is latitude; `r` is radius of search in meters (if not specified, defaults to 100 meters)
`GET /api/v1/operators?bbox=-122.4183,37.7758,-122.4120,37.7858` | `bbox` is a search bounding box with southwest longitude, southwest latitude, northeast longitude, northeast latitude (separated by commas)
`GET /api/v1/routes` | none required
`GET /api/v1/routes?identifer=19X` | `identifier` can be any type of route identifier
`GET /api/v1/routes?operatedBy=o-9q9-BART` | `operatedBy` is a Onestop ID for an operator/agency
`GET /api/v1/routes?bbox=-122.4183,37.7758,-122.4120,37.7858` | `bbox` is a search bounding box with southwest longitude, southwest latitude, northeast longitude, northeast latitude (separated by commas)

Pagination for JSON endpoints:
- `?offset=50` is the index of the first entity to be displayed (starts with 0)
- by default, 50 entities are displayed per page

Format:
- by default, responses are paginated JSON
- specify `.geojson` instead for GeoJSON on some endpoints. For example: `/api/v1/stops.geojson?bbox=-122.4183,37.7758,-122.4120,37.7858`
