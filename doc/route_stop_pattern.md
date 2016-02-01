# Transitland RouteStopPattern

Transitland models route geometries by breaking them into individual pieces called RouteStopPatterns.

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
| is_generated                 | Boolean  | Geometry has been created because the original shape reference or coordinates are missing. Currently, geometries are generated solely from the stop points.   |

### Onestop ID
RouteStopPatterns are uniquely defined by a Onestop Id, but the composition of this id is different from that of
Route, Stop, Feed, and Operator Onestop Ids. The RouteStopPattern Onestop Id has 5 components instead of 3, with each component separated by a dash as the ids of the latter Transitland entities. The first 3 components are exactly the Route Onestop Id of the Route to which the RouteStopPattern belongs to. The fourth component is the first 6 hexadecimal characters of the MD5 hash produced from the stop pattern string. The fifth component is the first 6 hexadecimal characters of the MD5 hash produced from geometry coordinates as a string.

### Distance calculation algorithm

Each ScheduleStopPair will be associated to a RouteStopPattern. In addition, two attributes have been added to ScheduleStopPair:
origin_distance_traveled and destination_distance_traveled.

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
  route_stop_patterns: [
    {
      identifiers: [],
      imported_from_feed_onestop_ids: [
        "f-9q9-actransit"
      ],
      imported_from_feed_version_sha1s: [
        "99a690251c960d301a9f3df4894c6a93f627698d"
      ],
      created_or_updated_in_changeset_id: 112,
      onestop_id: "r-9q9n-1-d04eb1-b69248",
      route_onestop_id: "r-9q9n-1",
      stop_pattern: [],
      geometry: {},
      is_generated: false,
      is_modified: false,
      created_at: "2016-01-27T03:02:13.453Z",
      updated_at: "2016-01-27T03:02:13.453Z",
      trips: [],
      tags: {
        shape_id: "10017"
      }
    }
  ],
  meta: {
    offset: 0,
    per_page: 50
  }
}
````
