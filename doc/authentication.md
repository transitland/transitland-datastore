# Authentication

## API

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
