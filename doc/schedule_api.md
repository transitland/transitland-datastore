# Schedule API

This is an evolving document describing the Schedule query parameters and responses.

# Query parameters

## From an origin
/api/v1/schedules?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation
(248)

## To a destination
/api/v1/schedules?destination_onestop_id=s-9q8vzhbggj-millbraecaltrainstation
(218)

## On a date
/api/v1/schedules?date=20150805
(1383)

## On a route
/api/v1/schedules?route_onestop_id=r-9q9-local
(3242)

## Edges originating for all stops in a bounding box
/api/v1/schedules?bbox=-122.4131,37.7136,-122.3789,30.8065
(4661)

# Combining query parameters

## For a stop on a date
/api/v1/schedules?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation&date=20150805
(46, verified)
## ... on a route
/api/v1/schedules?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation&date=20150805&route_onestop_id=r-9q9j-bullet
(11, verified)

## For a given stop pair
/api/v1/schedules?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation&destination_onestop_id=s-9q8vzhbggj-millbraecaltrainstation
(10)
## ... on a date
/api/v1/schedules?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation&destination_onestop_id=s-9q8vzhbggj-millbraecaltrainstation&date=20150805
(6, verified)
## ... on in a route
/api/v1/schedules?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation&destination_onestop_id=s-9q8vzhbggj-millbraecaltrainstation&date=20150805&route_onestop_id=r-9q9j-bullet
(6, verified)

# Response format

/api/v1/schedules?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation&per_page=1

````json
{
    "meta": {
        "next": "http://localhost:3000/api/v1/schedules?offset=1&per_page=1",
        "offset": 0,
        "per_page": 1,
        "total": 6
    },
    "schedules": [
        {
            "origin_onestop_id": "s-9q8yyugptw-sanfranciscocaltrainstation",
            "origin_arrival_time": "17:33:00",
            "origin_departure_time": "17:33:00",
            "destination_onestop_id": "s-9q8vzhbggj-millbraecaltrainstation",
            "destination_arrival_time": "17:49:00",
            "destination_departure_time": "17:49:00",
            "route_onestop_id": "r-9q9j-bullet",
            "trip": "6507698-CT-14OCT-Combo-Weekday-01",
            "trip_headsign": null,
            "service_start_date": "2015-04-27",
            "service_end_date": "2024-10-04",
            "service_except_dates": [],
            "service_days_of_week": [
                true,
                true,
                true,
                true,
                true,
                false,
                false
            ],
            "created_at": "2015-08-07T07:33:16.737Z",						
            "updated_at": "2015-08-07T07:33:16.737Z"
        }
    ]
}
````

The response will contain an array of schedules. Each schedule represents an edge between two stops as well as the service schedule.

 * origin_onestop_id: Stop ID for origin
 * origin_arrival_time: Vehicle arrives at origin
 * origin_departure_time: Vehicle leaves origin
 * destination_onestop_id: Stop ID for destination
 * destination_arrival_time: Vehicle arrives at destination
 * destination_departure_time: Vehicle leaves destination to next edge
 * route_onestop_id: Route ID for destination
 * trip: A text label for a sequence of edges
 * trip_headsign: A human friendly description of the ultimate destination
 * service_start_date: Date service begins
 * service_end_date: Date service ends
 * service_added_dates: Array of additional dates service is scheduled
 * service_except_dates: Array of dates service is NOT scheduled (Holidays, etc.)
 * service_days_of_week: Scheduled service, in ISO order (Monday -> Sunday)

