# Transitland Datastore Changesets

The only way to create, edit, and destroy data in the Transitland Datastore is through changesets. Each changeset contains a JSON payload of actions. When the changeset is applied, those actions are carried out on the database. Old records are retained in the database, but they're no longer marked as `current`. The new records are marked as `current` and given an appropriate `version_number` (1 greater than before, in the case of edited records). Destroyed records are "soft" deleted from the database.

## Using the API

To create, check, and apply a changeset, you can either do each step as a separate HTTP request to the API, or you can try it in one-go. Make sure to include an [API Auth Key](../readme.md#api-authentication) in your requests.

### Step by Step

1. Create an empty changeset: `POST /api/v1/changesets` with JSON like this in the request body:

  ````json
  {
    "changeset": {
      "notes": "In this changeset, we are creating or editing a stop. If a stop with this Onestop ID already exists, we'll just update its name. If it does not already exist, we will create it."
    }
  }
  ````

2. In the response, you'll get an ID for the changeset.

3. Add changes to a changeset using the 'PUT /api/v1/changesets/143/change_payloads' endpoint (assuming that the ID you got back in Step 2 is `143`) :

````json
{
  "change_payload": {
    "payload": {
      "changes": [
        {
          "action": "createUpdate",
          "stop": {
            "onestopId": "s-9q8yt4b-1avhos",
            "name": "1st Ave. & Holloway Street"
          }
        }
      ]
    }
  }
}
````

4. Check that the changeset can be cleanly applied to the database: `POST /api/v1/changesets/143/check`

5. Apply the changeset: `POST /api/v1/changesets/143/apply`

### Changeset Properties

Property | Required | Description
-------- | -------- | -----------
`notes` | - | a few sentences or a paragraph of plain text describing the changes

### ChangePayload Properties

Property | Required | Description
-------- | -------- | -----------
`payload` | yes | see below


### Payload Format
The payload is a JSON object. It's an array of change actions:

````json
"changes": []
````

Each payload can contain one or more change actions.

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
