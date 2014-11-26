[![Circle CI](https://circleci.com/gh/transit-land/onestop.png?style=badge)](https://circleci.com/gh/transit-land/onestop)
[![Dependency Status](https://gemnasium.com/transit-land/onestop.svg)](https://gemnasium.com/transit-land/onestop)

# Transit.land Onestop

A community-run directory of transit stops and their various identifiers.

Behind the scenes: a Ruby on Rails web service, backed by Postgres/PostGIS.

## Data Model

![diagram of Onestop's data model](https://rawgit.com/transit-land/onestop/master/doc/data-model.svg)

## To Develop Locally

1. Install dependencies:

    ````
    brew install postgis
    brew install redis
    brew install graphviz
    bundle install
    ````

2. Configure your local copy by renaming the example files to `config/application.yml` and `config/database.yml`. Edit as appropriate.

3. Create a local database, run migrations, and load seed data (GTFS files for San Francisco MTA and San Jose VTA): `bundle exec rake db:setup`

4. Start the server: `bundle exec rails server`


## To Import a GTFS Feed

* Import a local file by running: `bundle exec rake import_from_gtfs[spec/support/example_gtfs_archives/vta_gtfs.zip]` with the relative path to a local GTFS .zip archive
* Import a remote file by running: `bundle exec rake import_from_gtfs[http://gtfs.s3.amazonaws.com/santa-cruz-metro_20140607_0125.zip]` with a URL to a GTFS .zip archive

## To Run Tests Locally

1. Install dependencies: `brew install chromedriver` (as well as a copy of the latest Chrome)
2. Run the full test suite: `bundle exec rake`
3. To view coverage report: `open coverage/index.html`

## API Endpoints

Example URL  | Parameters
---------------|------------
`/api/v1/stops` | none required
`/api/v1/stops?identifer=4973` | `identifier` can be any type of stop identifier
`/api/v1/stops?lon=-121.977772198&lat=37.413530093&r=100` | `lon` is longitude; `lat` is latitude; `r` is radius of search in meters (if not specified, defaults to 100 meters)
`/api/v1/stops?bbox=-122.4183,37.7758,-122.4120,37.7858` | `bbox` is a search bounding box with southwest longitude, southwest latitude, northeast longitude, northeast latitude (separated by commas)

Pagination for JSON endpoints:
- `?offset=50` is the index of the first stop to be displayed (starts with 0)
- by default, 50 stops are displayed per page

Format:
- by default, responses are paginated JSON
- specify `.geojson` instead for GeoJSON on any endpoint. For example: `/api/v1/stops.geojson?bbox=-122.4183,37.7758,-122.4120,37.7858`
