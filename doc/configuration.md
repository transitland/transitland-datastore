# Configuration

The Datastore is configured by two methods:

- values in `config/application.yml`
- environment variables

Environment variables take precendence over values in the YML file.

key | possible values | default | description
--- | --------------- | ------- | -----------
`RUN_GOOGLE_FEEDVALIDATOR` | `true`, `false` | `true` | By default, FeedEaterWorker will validate feeds using the [Google transitfeed Python library](https://github.com/google/transitfeed). Set to `false` in order to skip this step.
`ATTACHMENTS_S3_REGION` | [any AWS S3 region](http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region) | `us-east-1` | used for uploading FeedEater artifacts
`ATTACHMENTS_S3_BUCKET` | name of an AWS S3 bucket | none | used for uploading FeedEater artifacts
