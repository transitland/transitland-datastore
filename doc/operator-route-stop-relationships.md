# Operator-Route-Stop Relationships
<script src="https://cdn.rawgit.com/knsv/mermaid/0.3.5/dist/mermaid.full.js"></script>

GTFS requires that complete information be provided about an agency, its routes, each trip of each route, and the exact time that each trip arrives or departs each stop. It's only through this entire set of entities and relationships that it's possible to say, for example, that *SFMTA serves Van Ness Station*.

 Transitland Datastore provides a more flexible model with different resolutions of temporal and geographic scale:

Resolution | Geographic Scale of Connectivity | Temporal Scale of Service
---------- | -------------------------------  | -------------------------
[R1](#r1) | + operator service area | - none
[R2](#r2) | ++ route line | - none
[R3](#r3) | ++ route line | + headway
[R4](#r4) | ++ route line | ++ arrival/departure time

R4 is equivalent to GTFS.

<p style="color: red;">WARNING/TODO: R3 and R4 have not yet been finalized or implemented.</p>

<a name="r1"></a>
## R1: an operator serves a stop

<div class="mermaid">
  graph LR
    Operator-->OperatorServingStop
    OperatorServingStop-->Stop
</div>

An R1 relationship can be created from either end:

* `operator.serves = ['STOP-ONESTOP-ID']`
* `operator.doesNotServe = ['STOP-ONESTOP-ID']`

An R1 relationship can also be destroyed from either end:

* `stop.servedBy = ['OPERATOR-ONESTOP-ID']`
* `stop.notServedBy = ['OPERATOR-ONESTOP-ID']`

Here's an example [changeset](changesets.md):

````json
  {
    "changeset": {
      "whenToApply": "instantlyIfClean",
      "payload": {
        "changes": [
          {
            "action": "createUpdate",
            "stop": {
              "onestopId": "s-9q8yt4b-19Hollway",
              "name": "19th Ave & Holloway St"
            }
          },
          {
            "action": "createUpdate",
            "operator": {
              "onestopId": "o-9q8y-SFMTA",
              "name": "San Francisco Municipal Transportation Agency",
              "serves": ["s-9q8yt4b-19Hollway"]
            }
          }
        ]
      },
      "notes": "In this changeset, we are creating/editing a stop and an operator, and we're specifying a relationship between the two."
    }
  }
````

Behind the scenes, an `OperatorServingStop` association-object will be created (or destroyed) as need be.

<a name="r2"></a>
## R2: a route serves a stop

<div class="mermaid">
  graph LR
    Operator-.->OperatorServingStop
    OperatorServingStop-.->Stop
    Operator-->Route
    Route-->RouteServingStop
    RouteServingStop-->Stop
    classDef outOfFocus fill:#fff,stroke:#ccc,stroke-width:4px
    class OperatorServingStop outOfFocus
</div>

First, each route must be associated with its operator:

* `route.operatedBy = ['OPERATOR-ONESTOP-ID']`

An R2 relationship can be created from either end:

* `route.serves = ['STOP-ONESTOP-ID']`
* `route.doesNotServe = ['STOP-ONESTOP-ID']`

An R2 relationship can also be destroyed from either end:

* `stop.servedBy = ['ROUTE-ONESTOP-ID']`
* `stop.notServedBy = ['ROUTE-ONESTOP-ID']`

Behind the scenes, both `RouteServingStop` and `OperatorServingStop` association-objects will be created (or destroyed) as need be.

Here's an example [changeset](changesets.md):

````json
  {
    "changeset": {
      "whenToApply": "instantlyIfClean",
      "payload": {
        "changes": [
          {
            "action": "createUpdate",
            "stop": {
              "onestopId": "s-9q8yt4b-19Hollway",
              "name": "19th Ave & Holloway St"
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
            "route": {
              "onestopId": "r-9q8y-19Express",
              "name": "Fictional 19th Ave. Express",
              "operatedBy": "o-9q8y-SFMTA",
              "serves": ["s-9q8yt4b-19Hollway"]
            }
          }
        ]
      },
      "notes": "In this changeset, we are creating/editing a stop, an operator, and a route. Also, we're specifying relationships among the three."
    }
  }
````

<a name="r3"></a>
## R3: frequency/headway at which a route serves a stop

<p style="color: red;">WARNING/TODO: R3 has not yet been finalized or implemented.</p>

<div class="mermaid">
  graph LR
    Operator-.->OperatorServingStop
    OperatorServingStop-.->Stop
    Operator-->Route
    Route-.->RouteServingStop
    RouteServingStop-.->Stop
    Route-->RouteFrequency
    RouteFrequency-->RouteFrequencyServingStop
    RouteFrequencyServingStop-->Stop
    classDef outOfFocus fill:#fff,stroke:#ccc,stroke-width:4px
    class OperatorServingStop,RouteServingStop outOfFocus
</div>

<a name="r4"></a>
## R4: exact arrival/depature times at which a route serves a stop

<p style="color: red;">WARNING/TODO: R4 has not yet been finalized or implemented.</p>

<div class="mermaid">
  graph LR
    Operator-.->OperatorServingStop
    OperatorServingStop-.->Stop
    Operator-->Route
    Route-.->RouteServingStop
    RouteServingStop-.->Stop
    Route-->RouteFrequency
    RouteFrequency-.->RouteFrequencyServingStop
    RouteFrequencyServingStop-.->Stop
    RouteFrequency-->Trip
    Trip-->StopTime
    StopTime-->Stop
    classDef outOfFocus fill:#fff,stroke:#ccc,stroke-width:4px
    class OperatorServingStop,RouteServingStop,RouteFrequencyServingStop outOfFocus
</div>
