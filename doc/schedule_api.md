# Schedule API

This is an evolving document describing the Schedule query parameters and responses.

# Query parameters

## From an origin
/api/v1/schedule_stop_pairs?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation

## To a destination
/api/v1/schedule_stop_pairs?destination_onestop_id=s-9q8vzhbggj-millbraecaltrainstation

## On a date
/api/v1/schedule_stop_pairs?date=2015-08-05

## On a route
/api/v1/schedule_stop_pairs?route_onestop_id=r-9q9-local

## Edges originating for all stops in a bounding box
/api/v1/schedule_stop_pairs?bbox=-122.4131,37.7136,-122.3789,30.8065

## Current, and future, service from a starting date
/api/v1/schedule_stop_pairs?service_from_date=2015-08-05

# Combining query parameters

## For a stop on a date
/api/v1/schedule_stop_pairs?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation&date=2015-08-05

## ... on a route
/api/v1/schedule_stop_pairs?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation&date=2015-08-05&route_onestop_id=r-9q9j-bullet

## For a given stop pair
/api/v1/schedule_stop_pairs?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation&destination_onestop_id=s-9q8vzhbggj-millbraecaltrainstation

## ... on a date
/api/v1/schedule_stop_pairs?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation&destination_onestop_id=s-9q8vzhbggj-millbraecaltrainstation&date=2015-08-05

## ... on in a route
/api/v1/schedule_stop_pairs?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation&destination_onestop_id=s-9q8vzhbggj-millbraecaltrainstation&date=2015-08-05&route_onestop_id=r-9q9j-bullet

# Response format

/api/v1/schedule_stop_pairs?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation&per_page=1

````json
{
    "meta": {
        "next": "http://localhost:3000/api/v1/schedule_stop_pairs?offset=1&per_page=1",
        "offset": 0,
        "per_page": 1,
        "total": 6
    },
    "schedule_stop_pairs": [
				{
					origin_onestop_id: "s-9q8yyugptw-sanfranciscocaltrainstation",
					origin_arrival_time: "14:53:00",
					origin_departure_time: "14:53:00",
					destination_onestop_id: "s-9q8yw8y448-bayshorecaltrainstation",
					destination_arrival_time: "15:13:00",
					destination_departure_time: "15:13:00",
					route_onestop_id: "r-9q8yw-sx",
					trip: "8447926-ME01-Calshut-Sunday-50",
					trip_headsign: "Bayshore",
					block_id: null,
					trip_short_name: "222885",
					wheelchair_accessible: null,
					bikes_allowed: null,
					pick_up_type: null,
					drop_off_type: null,
					timepoint: null,
					service_start_date: "2015-06-07",
					service_end_date: "2015-06-07",
					service_added_dates: [ ],
					service_except_dates: [ ],
					service_days_of_week: [
						false,
						false,
						false,
						false,
						false,
						false,
						true
					],
					created_at: "2015-08-11T23:57:20.529Z",
					updated_at: "2015-08-11T23:57:20.529Z"
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
 * block_id: 
 * trip_short_name: 
 * wheelchair_accessible:
 * bikes_allowed: 
 * pick_up_type:
 * drop_off_type:
 * timepoint:
 * service_start_date: Date service begins
 * service_end_date: Date service ends
 * service_added_dates: Array of additional dates service is scheduled
 * service_except_dates: Array of dates service is NOT scheduled (Holidays, etc.)
 * service_days_of_week: Scheduled service, in ISO order (Monday -> Sunday)

