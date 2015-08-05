# Schedule API

This is an evolving document describing the Schedule query parameters and responses.

# Query parameters

## From an origin
http://localhost:3000/api/v1/schedules?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation
(248)

## To a destination
http://localhost:3000/api/v1/schedules?destination_onestop_id=s-9q8vzhbggj-millbraecaltrainstation
(218)

## On a date
http://localhost:3000/api/v1/schedules?date=20150805
(1383)

## On a route
http://localhost:3000/api/v1/schedules?route_onestop_id=r-9q9-local
(3242)

## Edges originating for all stops in a bounding box
http://localhost:3000/api/v1/schedules?bbox=-122.4131,37.7136
(4661)

# Combining query parameters

## For a stop on a date
http://localhost:3000/api/v1/schedules?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation&date=20150805
(46, verified)
## ... on a route
http://localhost:3000/api/v1/schedules?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation&date=20150805&route_onestop_id=r-9q9j-bullet
(11, verified)

## For a given stop pair
http://localhost:3000/api/v1/schedules?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation&destination_onestop_id=s-9q8vzhbggj-millbraecaltrainstation
(10)
## ... on a date
http://localhost:3000/api/v1/schedules?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation&destination_onestop_id=s-9q8vzhbggj-millbraecaltrainstation&date=20150805
(6, verified)
## ... on in a route
http://localhost:3000/api/v1/schedules?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation&destination_onestop_id=s-9q8vzhbggj-millbraecaltrainstation&date=20150805&route_onestop_id=r-9q9j-bullet
(6, verified)

# Response format

http://localhost:3000/api/v1/schedules?origin_onestop_id=s-9q8yyugptw-sanfranciscocaltrainstation&per_page=1

````json
	{
	    "meta": {
	        "next": "http://localhost:3000/api/v1/schedules?offset=1&per_page=1",
	        "offset": 0,
	        "per_page": 1,
	        "total": 248
	    },
	    "schedules": [
	        {
	            "id": 2664,
	            "origin_id": 8,
	            "origin_arrival_time": "12:53:00",
	            "origin_departure_time": "12:53:00",
	            "destination_id": 24,
	            "destination_arrival_time": "13:13:00",
	            "destination_departure_time": "13:13:00",
	            "route_id": 5,
	            "frequency_start_time": null,
	            "frequency_end_time": null,
	            "frequency_headway_seconds": null,
	            "trip": "8446567-ME01-Calshut-Saturday-50",
	            "trip_headsign": null,
	            "service_start_date": "20150606",
	            "service_end_date": "20150606",
	            "service_added": null,
	            "service_except": null,
	            "service_sunday": false,
	            "service_monday": false,
	            "service_tuesday": false,
	            "service_wednesday": false,
	            "service_thursday": false,
	            "service_friday": false,
	            "service_saturday": true,
	            "tags": null,
	            "version": 1
	            "created_at": "2015-08-05T00:49:18.793Z",
	            "created_or_updated_in_changeset_id": 2,
	            "updated_at": "2015-08-05T00:49:18.793Z",
	        }
	    ]
	}
````

The response will contain an array of schedules. Each schedule represents an edge between two stops as well as the service schedule.

 * origin_id: Internal Stop ID for origin
 * origin_arrival_time: Vehicle arrives at origin
 * origin_departure_time: Vehicle leaves origin
 * destination_id: Internal Stop ID for destination
 * destination_arrival_time: Vehicle arrives at destination
 * destination_departure_time: Vehicle leaves destination to next edge
 * route_id: Internal Route ID for destination
 * frequency_start_time: 
 * frequency_end_time:
 * frequency_headway_seconds:
 * trip: A text label for a sequence of edges
 * trip_headsign: A human friendly description of the ultimate destination
 * service_start_date: Date service begins
 * service_end_date: Date service ends
 * service_added: Array of additional dates service is scheduled
 * service_except: Array of dates service is NOT scheduled (Holidays, etc.)
 * service_<day of week>: Generally scheduled service on <day of week>

