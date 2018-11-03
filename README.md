[![Circle CI](https://circleci.com/gh/transitland/transitland-datastore.png?style=badge)](https://circleci.com/gh/transitland/transitland-datastore)

# Transitland Datastore

A community-run and -edited timetable and map of public transit service around the world.

***For more information about Transitland as a whole, and how to use the Datastore in particular, view the [Transitland documentation site](https://transit.land/documentation).***

This readme describes the Transitland Datastore behind the scenes: a Ruby on Rails web service (backed by Postgres/PostGIS), along with an asynchronous Sidekiq queue (backed by Resque) that runs Ruby and Python data-ingestion libraries.

Note that this web application is designed to run at `https://transit.land/api/v1` While you're welcome to try hosting your own instance, please keep in mind that the Transitland Datastore is intended to be a centralized source of data run by a community in one place (much like [the Rails app that powers the openstreetmap.org API](https://github.com/openstreetmap/openstreetmap-website)).

## Technical documentation

- [API endpoints](https://transit.land/documentation/datastore/api-endpoints.html)
- [Local instructions](doc/local-instructions.md)
- [Configuration reference](doc/configuration.md)
- [Development practices](doc/development-practices.md)
- [Conflation with OSM](doc/conflation-with-osm.md)
- [Admin interface](doc/admin-interface.md)
- [Authentication](doc/authentication.md)

## See also

- [changelog](CHANGELOG.md)
- [contributing](CONTRIBUTING.md)
- [license](LICENSE.txt)
