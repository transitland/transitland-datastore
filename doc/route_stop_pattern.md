# Transitland RouteStopPattern

Transitland models route geometries by breaking them into individual components called Route Stop Patterns. These components are uniquely defined by a route, a stop pattern, and a line geometry; all three derived from the trip routes, trip stop sequences, and shapes of a GTFS feed. Because of this, it is possible to have two distinct Route Stop Patterns within one route, both sharing the same line geometry but having different stop patterns, and vice versa. Individual Route Stop Patterns also have records of the GTFS trips and the single shape used to create them; a typical Route Stop Pattern will reference back to one or many trips having the same stop pattern, but only references the one shape shared by those trips. When a Route Stop Pattern's trips have no shapes or empty shapes, there will be no shape reference.

Route Stop Patterns may also modify the original shape line geometry if necessary. When this is done, a Boolean value named `is_modified` will be set to true. Currently, the line geometry is only modified in two situations: when it is generated as the result of missing its original GTFS shape id or shape points, and when the first and/or last stops are determined to be before or after the line geometry. In the case of generation, the line geometry becomes the sequential points of the stop pattern, and a separate boolean named `is_generated` will be set to true. In the case where a first or last stop is found to be before or after the line geometry, its coordinates are added to the beginning or end of the line geometry. Please see the section
"Before and After Stops" for more information on how that determination is done.

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
Route, Stop, Feed, and Operator Onestop Ids. The RouteStopPattern Onestop Id has 5 components instead of 3, with each component separated by a dash just as the ids of the latter Transitland entities. The first 3 components are exactly the Route Onestop Id of the Route to which the RouteStopPattern belongs to. The fourth component is the first 6 hexadecimal characters of the MD5 hash produced from the stop pattern string (stop onestop id's separated by comma). The fifth component is the first 6 hexadecimal characters of the MD5 hash produced from geometry coordinates as a string (coordinates separated by comma).

### Before and After Stops
A stop is considered to be before (after) a Route Stop Pattern line geometry if its point satisfies one of two conditions:

1. It is found on the opposite side of the line that is perpendicular to the first (last) line segment and that passes through the first (last) endpoint of the segment.

2. It is greater than 100 meters distant from any point in the line geometry.

For example:

Before:

&emsp;&emsp;&emsp;&emsp; | <br/>
&emsp;&emsp;&emsp;&nbsp;x |-----------> <br/>
&emsp;&emsp;&emsp;&emsp;  |

Before:

&emsp;&emsp;&emsp;&emsp;    | <br/>
&emsp;&emsp;&emsp;&emsp;  |-----------> <br/>
&emsp;&emsp;&emsp;&emsp; | ]  100 m  <br/>
&emsp;&emsp;&emsp;&emsp;&emsp;&emsp; x

Not before:

&emsp;&emsp;&emsp;&emsp;    | <br/>
&emsp;&emsp;&emsp;&emsp;  |-----------> <br/>
&emsp;&emsp;&emsp;&emsp; | x &emsp;&emsp;]  100 m  <br/>
&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;


### Distance calculation algorithm
Each Schedule Stop Pair will be associated to a RouteStopPattern. In addition, two attributes have been added to Schedule Stop Pair: origin_distance_traveled and destination_distance_traveled. These are the distances, in meters rounded to the nearest decimeter, of the origin and destination stops along the line geometry from the start point.

The algorithm to compute these distances runs as follows:

  1. Initialize the total distance traveled counter to 0.0.

  2. Initialize an evaluation line geometry and set it to the complete Route Stop Pattern line geometry.

  3. For each stop in the stop pattern:
    1. Find its nearest point to the line geometry. This is accomplished by projecting the stop point
    and line into Cartesian coordinates, finding the nearest line segment to the stop point, and then finding
    the nearest point on that segment.
    2. Once the nearest point is found, split the line at this point into two.
    3. For the first half of the split, project the segments back into spherical coordinates to calculate their lengths. Sum these lengths and add that sum to the total distance counter. Store the current stop's distance as the updated total distance counter.
    4. The second half of the split is now the evaluation line geometry. Repeat step 3 (stop pattern iteration) with this evaluation line and with the next stop in the stop pattern.

  The algorithm should never run out of evaluation line to split, since we add the last stop if it is found past the last endpoint of the line. If there is a complication in the split computation, this should indicate an outlier stop, the result is logged, and that stop receives a distance value equal to the previous stop.

## Query parameters

The main RouteStopPattern API endpoint is [/api/v1/route_stop_patterns](http://transit.land/api/v1/route_stop_patterns). It accepts the following query parameters, which may be freely combined.

| Query parameter        | Type | Description | Example |
|------------------------|------|-------------|---------|
| onestop_id             | Onestop ID | RouteStopPattern. | (http://transit.land/api/v1/route_stop_patterns?onestop_id=r-9q9-pittsburg~baypoint~sfia~millbrae-49ae87-5ae164) |
| traversed_by   | Onestop ID | Route. Accepts multiple route onestop ids separated by commas. | [belonging to Route Pittsburg/Bay Point - SFIA/Millbrae](http://transit.land/api/v1/route_stop_patterns?traversed_by=r-9q9-pittsburg~baypoint~sfia~millbrae)
| stops_visited  | Onestop ID | Stop. Accepts multiple separated by commas. | [Having stop MacArthur](http://transit.land/api/v1/route_stop_patterns?stops_visited=s-9q9p1wrwrp-macarthur)
| trips | String | Derived from trip. Accepts multiple trips ids separated by commas. | [Having trips ](http://transit.land/api/v1/route_stop_patterns?trips=01SFO10,96SFO10)
| bbox                     | Lon1,Lat1,Lon2,Lat2 | Route Stop Patterns within bounding box | [in the Bay Area](http://transit.land/api/v1/route_stop_patterns?bbox=-123.057,36.701,-121.044,38.138)

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
