# Configuration

The Datastore is configured by two methods:

- values in `config/application.yml`
- environment variables

Environment variables take precendence over values in the YML file.

key | possible values | default | description
--- | --------------- | ------- | -----------
`RUN_GOOGLE_FEEDVALIDATOR` | `true`, `false` | `true` | By default, FeedEaterFeedWorker will validate feeds using the [Google transitfeed Python library](https://github.com/google/transitfeed). Set to `false` in order to skip this step.
`CREATE_FEED_EATER_ARTIFACTS` | `true`, `false` | `false` | If both this key and `AUTO_CONFLATE_STOPS_WITH_OSM` are set to `true`, then enriched GTFS feed archives will be produced after FeedEaterFeedWorker runs. (Enriched feeds include Onestop IDs and OSM way IDs for stops.)
