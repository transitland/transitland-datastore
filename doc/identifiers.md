# Identifiers

Identifiers are strings that can be attached to any entity (operator, stop, route). Identifiers can follow a URI-style scheme.

To add or remove identifiers from an entity, use `identifiedBy` and `notIdentifiedBy` in a [changeset payload](doc/changesets.md).

For example:

  ````json
  {
    "changeset": {
      "payload": {
        "changes": [
          {
            "action": "createUpdate",
            "stop": {
              "onestopId": "s-9q8yt4b-1AvHoS",
              "name": "1st Ave. & Holloway Street",
              "identifiedBy": ["gtfs://sfmta/343"],
              "notIdentifiedBy": ["gtfs://sfmta/422"]
            }
          }
        ]
      },
      "notes": "In this changeset, we are creating or editing a stop. If a stop with this Onestop ID already exists, we'll just update its name. If it does not already exist, we will create it."
    }
  }
  ````
