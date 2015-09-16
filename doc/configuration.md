# Configuration

The Datastore is configured by two methods:

- values in `config/application.yml`
- environment variables

Environment variables take precendence over values in the YML file.

key | possible values | default | description
--- | --------------- | ------- | -----------
`RUN_GOOGLE_FEEDVALIDATOR` | `true`, `false` | `true` | By default, FeedEaterFeedWorker will validate feeds using the [Google transitfeed Python library](https://github.com/google/transitfeed). Set to `false` in order to skip this step.
