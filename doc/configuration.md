# Configuration

The Datastore is configured by two methods:

- values in `config/application.yml`
- environment variables

Environment variables take precendence over values in the YML file.

key | possible values | default | description
--- | --------------- | ------- | -----------
`RUN_GOOGLE_VALIDATOR` | `true`, `false` | `false` | By default, FeedEaterWorker will validate feeds using the [Google transitfeed Python library](https://github.com/google/transitfeed). Set to `false` in order to skip this step.
`RUN_CONVEYAL_VALIDATOR` | `true`, `false` | `false` | Run Conveyal GTFS Validator.
`ATTACHMENTS_S3_REGION` | [any AWS S3 region](http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region) | `us-east-1` | used for uploading FeedEater artifacts
`ATTACHMENTS_S3_BUCKET` | name of an AWS S3 bucket | none | used for uploading FeedEater artifacts
`MAX_HOURS_SINCE_LAST_CONFLATE` | Any real number >= 0 | 84 hours | Stops that were last conflated before this number of hours before the re-conflation check time will be re-conflated.
`FEED_EATER_CHANGE_PAYLOAD_MAX_ENTITIES` | Any integer > 0 | 1,000 | Set the number of entities that FeedEaterWorker and FeedEaterScheduleWorker will put into each changeset
`FEED_EATER_STOP_TIMES_MAX_LOAD` | Any integer > 0 | 100,000 | When FeedEaterWorker spawns FeedEaterScheduleWorkers, this is the number of lines from a GTFS feed's `stop_times.txt` that will be sent to each FeedEaterScheduleWorker job
`SEND_CHANGESET_EMAILS_TO_USERS` | `true`, `false` | `true` | By default, e-mail notifications go out to a changeset's author (as long as the user isn't an admin)
`FEED_INFO_CACHE_EXPIRATION` | Any integer > 0 | 14400 seconds | Cache expiration time, in seconds, for FeedInfo results
`AUTO_FETCH_FEED_VERSION` | `true`, `false` | `false` | Automatically run FeedFetch to create FeedVersion when a Feed is created
`GTFS_GRAPH_VERSION` | `1`, `2` | `2` | Use legacy GTFSGraph by setting to 1. This option may be removed in the future.
`SMTP_ADDRESS` | `smtp.sparkpostmail.com` | none | send email notifications using this SMTP service
`SMTP_PORT` | 587 | none | port for SMTP service
`SMTP_USER_NAME` | `SMTP_Injection` | none | user name for SMTP service
`SMTP_PASSWORD` | your password | none | password for SMTP service
