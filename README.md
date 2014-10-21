[![Circle CI](https://circleci.com/gh/transit-land/onestop.png?style=badge)](https://circleci.com/gh/transit-land/onestop)

# Transit.land Onestop

A community-run directory of transit stops and their various identifiers.

Behind the scenes: a Ruby on Rails web service, backed by Postgres/PostGIS.

## To Develop Locally

1. Install dependencies:

    ````
    brew install postgis
    brew install redis
    bundle install
    ````

2. Configure your local copy by renaming the example files to `config/application.yml` and config/database.yml`. Edit as appropriate.

3. Start the server: `bundle exec rails server`

## To Run Tests Locally

1. Install dependencies: `brew install chromedriver` (as well as a copy of the latest Chrome)
2. Run the full test suite: `bundle exec rake`
3. To view coverage report: `open coverage/index.html`
