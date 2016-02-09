# Transitland RouteStopPattern

Transitland models route geometries by breaking them into individual components called Route Stop Patterns. In a
sense, you can also consider these components to be enhanced GTFS Shapes with added data and associations with other
Transitland entities. Route Stop Patterns are uniquely defined by route, stop sequence (called stop pattern), and a line geometry, all three derived from the trips and shapes of a feed. This deviates from GTFS, where shapes are generally unique
by line geometry only. Route Stop Patterns also have records of the GTFS trips and shape used to create them; a typical
Route Stop Pattern will reference back to many trips having the same stop pattern, but only references the one shape
shared by those trips. When a Route Stop Pattern's trips have no shapes or empty shapes, there will be no shape reference.

Transitland may also make modifications to the line geometry if necessary.

## RouteStopPattern Data Model

| Attribute                    | Type | Description |
|------------------------------|------|-------------|
| onestop_id                   | Onestop ID | RouteStopPattern
| route_onestop_id             | Onestop ID | Route |
| geometry                     | Geography  | LineString |
| stop_pattern                 | Onestop ID array  | List of stops along geometry in trip order. Stops may reappear. |
| identifiers                  | String array  | List of identifiers. |
| trips                        | String array  | List of trip ids  |
| tags                         | Hstore   | Associated shape id   |
| is_modified                  | Boolean  | Geometry has added or removed coordinates from the original shape  |
| is_generated                 | Boolean  | Geometry has been created because the original shape reference or coordinates are missing. Currently, geometries are auto-generated solely from the stop points.   |

### Onestop ID
RouteStopPatterns are uniquely identified by a Onestop Id, but the composition of this id is different from that of
Route, Stop, Feed, and Operator Onestop Ids. The RouteStopPattern Onestop Id has 5 components instead of 3, with each component separated by a dash just as the ids of the latter Transitland entities. The first 3 components are exactly the Route Onestop Id of the Route to which the RouteStopPattern belongs to. The fourth component is the first 6 hexadecimal characters of the MD5 hash produced from the stop pattern string. The fifth component is the first 6 hexadecimal characters of the MD5 hash produced from geometry coordinates as a string.

### Distance calculation algorithm

Each Schedule Stop Pair will be associated to a RouteStopPattern. In addition, two attributes have been added to Schedule Stop Pair: origin_distance_traveled and destination_distance_traveled. These are the distances, in meters rounded to the nearest
decimeter, of the origin and destination stops along the line geometry from the start point.

         x                            x
 x |------------x-------x---------------------| x

         x                            x
 0 |------------x-------x---------------------| x

        6                            x
 0      |-------x-------x---------------------| x

        6       7                     x
0               |-------x---------------------| x

        6       7       14              x
0                       |---------------------| x

The algorithm to compute these distances runs as follows:

  1) Initialize the total distance traveled counter to
  0.0.

  2) Determine whether the first stop of the stop pattern lies before the start point of the line geometry. If so, store that stop's distance as 0.0 and add the distance from that stop to the first point of the line geometry to the distance traveled of the second stop.
  3) For each stop in the stop pattern starting with the second stop,     



## Query parameters

The main RouteStopPattern API endpoint is [/api/v1/route_stop_patterns](http://transit.land/api/v1/route_stop_patterns). It accepts the following query parameters, which may be freely combined.

| Query parameter        | Type | Description | Example |
|------------------------|------|-------------|---------|
| onestop_id             | Onestop ID | RouteStopPattern. | (http://transit.land/api/v1/route_stop_patterns?onestop_id=r-9q9-pittsburg~baypoint~sfia~millbrae-49ae87-5ae164) |
| traversed_by   | Onestop ID | Route. Accepts multiple separated by commas. | [belonging to Route Pittsburg/Bay Point - SFIA/Millbrae](http://transit.land/api/v1/route_stop_patterns?traversed_by=r-9q9-pittsburg~baypoint~sfia~millbrae)
| stops_visited  | Onestop ID | Stop. Accepts multiple separated by commas. | [Having stop MacArthur](http://transit.land/api/v1/route_stop_patterns?stops_visited=s-9q9p1wrwrp-macarthur)
| trips | String | Derived from trip. Accepts multiple separated by commas. | [Having trips ](http://transit.land/api/v1/route_stop_patterns?trips=01SFO10,96SFO10)
| bbox                     | Lon1,Lat1,Lon2,Lat2 | Stop within bounding box | [in the Bay Area](http://transit.land/api/v1/route_stop_patterns?bbox=-123.057,36.701,-121.044,38.138)

## Response format

````json
{
  "route_stop_patterns": [
    {
      "identifiers": [
          "gtfs://f-9q9-caltrain/trip/147",
          "gtfs://f-9q9-caltrain/trip/RTD8550540",
          "gtfs://f-9q9-caltrain/trip/155",
          "gtfs://f-9q9-caltrain/trip/191",
          "gtfs://f-9q9-caltrain/trip/193",
          "gtfs://f-9q9-caltrain/trip/199",
          "gtfs://f-9q9-caltrain/trip/135",
          "gtfs://f-9q9-caltrain/trip/101",
          "gtfs://f-9q9-caltrain/trip/139",
          "gtfs://f-9q9-caltrain/trip/143",
          "gtfs://f-9q9-caltrain/trip/RTD8550531",
          "gtfs://f-9q9-caltrain/trip/RTD8550532",
          "gtfs://f-9q9-caltrain/trip/RTD8550533",
          "gtfs://f-9q9-caltrain/trip/RTD8550534",
          "gtfs://f-9q9-caltrain/trip/RTD8550535",
          "gtfs://f-9q9-caltrain/trip/RTD8550536",
          "gtfs://f-9q9-caltrain/trip/RTD8550537",
          "gtfs://f-9q9-caltrain/trip/RTD8550538",
          "gtfs://f-9q9-caltrain/trip/RTD8550539",
          "gtfs://f-9q9-caltrain/trip/151"
        ],
        "imported_from_feed_onestop_ids": [
          "f-9q9-caltrain"
        ],
        "imported_from_feed_version_sha1s": [
          "36ba71b654ba6ed1e4866822832c11942c4761e5"
        ],
        "created_or_updated_in_changeset_id": 10,
        "onestop_id": "r-9q9-local-f68455-dcd599",
        "route_onestop_id": "r-9q9-local",
        "stop_pattern": [
          "s-9q9k652x5g-caltrain~diridonstation",
          "s-9q9k3rbsm5-caltrain~santaclarastation",
          "s-9q9hxghghb-caltrain~lawrencestation",
          "s-9q9hxhefny-caltrain~sunnyvalestation",
          "s-9q9hwp7n80-caltrain~mountainviewstation",
          "s-9q9hv3gt1t-caltrain~sanantoniostation",
          "s-9q9hutfdz0-caltrain~californiaavestation",
          "s-9q9jh06g20-caltrain~paloaltostation",
          "s-9q9j5dmedf-caltrain~menloparkstation",
          "s-9q9j681ejk-caltrain~redwoodcitystation",
          "s-9q9j3uj1fs-caltrain~sancarlosstation",
          "s-9q9j3w3tux-caltrain~belmontstation",
          "s-9q9j916p33-caltrain~hillsdalestation",
          "s-9q9j8u1jr3-caltrain~haywardparkstation",
          "s-9q9j8qyzjx-caltrain~sanmateostation",
          "s-9q8vzcqbz3-caltrain~burlingamestation",
          "s-9q8vzh9pm5-caltrain~millbraestation",
          "s-9q8yn6qcdh-caltrain~sanbrunostation",
          "s-9q8ynwfu1e-caltrain~ssanfranciscostation",
          "s-9q8yw9n59m-caltrain~bayshorestation",
          "s-9q8yycsdkr-caltrain~22ndststation",
          "s-9q8yyv42k3-caltrain~sanfranciscostation"
        ],
        "geometry": {
          "type": "LineString",
          "coordinates": [
            [
              -121.903447,
              37.328642
            ],
            [
              -121.936346,
              37.352892
            ],
            [
              -121.996437,
              37.370515
            ],
            [
              -122.030683,
              37.378613
            ],
            [
              -122.075954,
              37.394458
            ],
            [
              -122.108158,
              37.40796
            ],
            [
              -122.142258,
              37.42952
            ],
            [
              -122.164182,
              37.44334
            ],
            [
              -122.182266,
              37.454382
            ],
            [
              -122.231594,
              37.485892
            ],
            [
              -122.259862,
              37.507648
            ],
            [
              -122.275574,
              37.520713
            ],
            [
              -122.297001,
              37.537416
            ],
            [
              -122.309097,
              37.552181
            ],
            [
              -122.32325,
              37.567616
            ],
            [
              -122.345145,
              37.580246
            ],
            [
              -122.386097,
              37.599223
            ],
            [
              -122.411291,
              37.629831
            ],
            [
              -122.405821,
              37.654972
            ],
            [
              -122.401366,
              37.711202
            ],
            [
              -122.392318,
              37.757692
            ],
            [
              -122.395406,
              37.776541
            ]
          ]
        },
        "is_generated": true,
        "is_modified": true,
        "created_at": "2016-02-06T20:05:59.645Z",
        "updated_at": "2016-02-06T20:05:59.645Z",
        "trips": [
          "147",
          "RTD8550540",
          "155",
          "191",
          "193",
          "199",
          "135",
          "101",
          "139",
          "143",
          "RTD8550531",
          "RTD8550532",
          "RTD8550533",
          "RTD8550534",
          "RTD8550535",
          "RTD8550536",
          "RTD8550537",
          "RTD8550538",
          "RTD8550539",
          "151"
        ],
        "tags": {
          "shape_id": null
        }
      }
    ],
    "meta": {
      "offset": 0,
      "per_page": 50,
      "next": "http://dev.transit.land/api/v1/route_stop_patterns?offset=50&per_page=50"
    }
}
````
