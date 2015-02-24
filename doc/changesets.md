# Transitland Datastore Changesets

The only way to create, edit, and destroy data in the Transitland Datastore is through changesets. Each changeset contains a JSON payload of actions. When the changeset is applied, those actions are carried out on the database. Old records are retained in the database, but they're no longer marked as `current`. The new records are marked as `current` and given an appropriate `version_number` (1 greater than before, in the case of edited records). Destroyed records are "soft" deleted from the database.

## Using the API

To create, check, and apply a changeset, you can either do each step as a separate HTTP request to the API, or you can try it in one-go.

### Step by Step

1. Create a changeset: `POST /api/v1/changesets` with JSON like this in the request body:

  ````json
  {
    "changeset": {
      "payload": {
        "changes": [
          {
            "action": "createUpdate",
            "stop": {
              "onestopId": "s-9q8yt4b-1AvHoS",
              "name": "1st Ave. & Holloway Street"
            }
          }
        ]
      },
      "notes": "In this changeset, we are creating or editing a stop. If a stop with this Onestop ID already exists, we'll just update its name. If it does not already exist, we will create it."
    }
  }
  ````

2. In the response, you'll get an ID for the changeset
3. Check that the changeset can be cleanly applied to the database: `POST /api/v1/changesets/143/check` (assuming that the ID you got back in Step 2 is `143`)
4. Apply the changeset: `POST /api/v1/changesets/143/apply`

### All in One Go

To create, check, and apply a changeset all in one API request: `POST /api/v1/changesets` with JSON like this in the request body. Note the `"whenToApply"` property:

  ````json
  {
    "changeset": {
      "whenToApply": "instantlyIfClean",
      "payload": {
        "changes": [
          {
            "action": "createUpdate",
            "stop": {
              "onestopId": "s-9q8yt4b-1AvHoS",
              "name": "1st Ave. & Holloway Street"
            }
          },
          {
            "action": "createUpdate",
            "operator": {
              "onestopId": "o-9q8y-SFMTA",
              "name": "San Francisco Municipal Transportation Agency"
            }
          },
          {
            "action": "createUpdate",
            "operatorRouteStopRelationship": {
              "operatorOnestopId": "o-9q8y-SFMTA",
              "stopOnestopId": "s-9q8yt4b-1AvHoS"
            }
          }

        ]
      },
      "notes": "In this changeset, we are creating/editing a stop, an operator, and the relationship between the two."
    }
  }
  ````

### Changeset Properties

Property | Required | Description
-------- | -------- | -----------
`payload` | yes | see below
`notes` | - | a few sentences or a paragraph of plain text describing the changes
`whenToApply` | - | Two options:<ul><li>`holdForReview`</li> (default, if none specified)<li>`instantlyIfClean`</li></ul>

### Payload Format
The payload is a JSON object. It's an array of change actions:

````json
"changes": []
````

Each changeset can contain one or more change actions.

The possible actions include `createUpdate` and `destroy`:

````json
"changes": [
  {
    "action": "createUpdate",
    "stop": {
      "onestopId": "s-9q8yt4b-1AvHoS",
      "name": "1st Ave. & Holloway Street"
    },
  },
  {
    "action": "destroy",
    "stop": {
      "onestopId": "s-9q8yt4b-2AvNo"
    }
  }
]
````

#### Payload JSON Schema
Payloads are validated using JSON schemas found in `/app/models/json_schemas`.

Note that the API consumers and produces JSON with `"camelCaseKeysInQuotationMarks"`, while internally, the Datastore uses `ruby_symbols_with_underscores`. 
