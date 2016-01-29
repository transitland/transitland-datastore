# Transitland RouteStopPattern

Transitland models each trip between two stops as an edge, called a `ScheduleStopPair`, or SSP. Each SSP contains an origin stop, a destination stop, a route, an operator, and arrival and departure times. Each edge also includes a service calendar, describing which days a trip is possible. Accessibility information for wheelchair and bicycle riders is included, if available. Some of this data is normally split across multiple GTFS tables, but is here denormalized for simpler access: each edge contains enough information to get from one stop to another, to another, and finally to your destination.

## RouteStopPattern Data Model

| Attribute                    | Type | Description |
|------------------------------|------|-------------|
| route_onestop_id             | Onestop ID | Route |
| operator_onestop_id          | Onestop ID | Operator |
| origin_onestop_id            | Onestop ID | Origin stop |
| origin_timezone              | String | Origin stop timezone |
| origin_arrival_time          | Time | Time vehicle arrives at origin from previous stop |
| origin_departure_time        | Time | Time vehicle leaves origin |
| origin_timepoint_source      | Enum | Origin timepoint source |
| destination_onestop_id       | Onestop ID | Destination stop |
| destination_timezone         | String | Destination stop timezone |
| destination_arrival_time     | Time | Time vehicle arrives at destination |
| destination_departure_time   | Time | Time vehicle leaves destination for next stop |
| destination_timepoint_source | Enum | Destination timepoint source |
| window_start                 | Time | The previous known exact timepoint |
| window_end                   | Time | The next known exact timepoint |
| trip                         | String | A text label for a sequence of edges |
| trip_headsign                | String | A human friendly description of the ultimate destination |
| trip_short_name              | String | A commonly known human-readable trip identifier, e.g. a train number |
| block_id                     | String | A block of trips made by the same vehicle |
| service_start_date           | Date | Date service begins |
| service_end_date             | Date | Date service ends |
| service_days_of_week         | Boolean Array | Scheduled service, in ISO order (Monday -> Sunday) |
| service_added_dates          | Date Array | Array of additional dates service is scheduled |
| service_except_dates         | Date Array | Array of dates service is NOT scheduled (Holidays, etc.) |
| wheelchair_accessible        | Boolean | Wheelchair accessible: true, false, or null (unknown) |
| bikes_allowed                | Boolean | Bike accessible: true, false, or null (unknown) |
| drop_off_type                | Enum | Passenger drop-off |
| pickup_type                  | Enum | Passenger pickup |

### Data types

Times can be specified with more than 24 hours, as specified by GTFS. For example, 25:10 is 1:10am the day after the trip begins.

Timepoint Source
 * gtfs_exact: An exact timepoint in the GTFS
 * gtfs_interpolated: An interpolated timepoint in the GTFS
 * transitland_interpolated_linear: Interpolated based on linear stop sequence
 * transitland_interpolated_geometric: Interpolated based on straight-line distance
 * transitland_interpolated_shape: Interpolated based on shape_dist_traveled

Pickup (origin) and drop-off (destination)
 * null: Regularly scheduled pickup and drop-off
 * unavailable: Pickup or drop-off not available
 * ask_driver: Ask the driver for pickup or drop-off
 * ask_agency: Phone agency to schedule in advance

## Query parameters

The main ScheduleStopPair API endpoint is [/api/v1/schedule_stop_pairs](http://transit.land/api/v1/schedule_stop_pairs). It accepts the following query parameters, which may be freely combined.

| Query parameter        | Type | Description | Example |
|------------------------|------|-------------|---------|
| origin_onestop_id        | Onestop ID | Origin Stop. Accepts multiple separated by commas. | [from Embarcadero BART](http://transit.land/api/v1/schedule_stop_pairs?origin_onestop_id=s-9q8znb12j1-embarcadero) |
| destination_onestop_id   | Onestop ID | Destination Stop. Accepts multiple separated by commas. | [to Montgomery St. BART](http://transit.land/api/v1/schedule_stop_pairs?destination_onestop_id=s-9q8yyxq427-montgomeryst)
| route_onestop_id         | Onestop ID | Route. Accepts multiple separated by commas. | [on Muni N](http://transit.land/api/v1/schedule_stop_pairs?route_onestop_id=r-9q8y-n) |
| operator_onestop_id      | Onestop ID | Operator. Accepts multiple separated by commas. | [on BART](http://transit.land/api/v1/schedule_stop_pairs?operator_onestop_id=o-9q9-bart) |
| service_date             | Date | Service operates on a date | [valid on 2015-10-26](http://transit.land/api/v1/schedule_stop_pairs?date=2015-10-26) |
| service_from_date        | Date | Service operates on a date, or in the future | [valid on and after 2015-10-26](http://transit.land/api/v1/schedule_stop_pairs?service_from_date=2015-10-26) |
| origin_departure_between | Time,Time | Origin departure time between two times | [departing between 07:00 - 09:00](http://transit.land/api/v1/schedule_stop_pairs?origin_departure_between=07:00:00,09:00:00) |
| trip                     | String | Trip identifier | [on trip '03SFO11SUN'](http://transit.land/api/v1/schedule_stop_pairs?trip=03SFO11SUN) |
| bbox                     | Lon1,Lat1,Lon2,Lat2 | Origin Stop within bounding box | [in the Bay Area](http://transit.land/api/v1/schedule_stop_pairs?bbox=-123.057,36.701,-121.044,38.138)

## Response format

````json
{
    "schedule_stop_pairs": [
        {
            "route_onestop_id": "r-dr5r-2",
            "operator_onestop_id": "o-dr5r-nyct",
            "origin_onestop_id": "s-dr5ru0smu8-18st",
            "origin_arrival_time": "25:35:00",
            "origin_departure_time": "25:35:00",
            "origin_timepoint_source": "gtfs_exact",
            "origin_timezone": "America/New_York",
            "destination_onestop_id": "s-dr5ru1np2p-23st",
            "destination_arrival_time": "25:36:00",
            "destination_departure_time": "25:36:00",
            "destination_timepoint_source": "gtfs_exact",
            "destination_timezone": "America/New_York",
            "window_end": "25:36:00",
            "window_start": "25:35:00",
            "trip": "A20150614WKD_149100_2..N08R",
            "trip_headsign": "WAKEFIELD - 241 ST",
            "trip_short_name": null,
            "block_id": null,
            "service_start_date": "2015-06-14",
            "service_end_date": "2016-12-31",
            "service_days_of_week": [
                true,
                true,
                true,
                true,
                true,
                false,
                false
            ],
            "service_added_dates": [],
            "service_except_dates": [
                "2015-09-07",
                "2015-11-26"
            ],
            "shape_dist_traveled": 0.0,
            "wheelchair_accessible": true,
            "bikes_allowed": true,
            "drop_off_type": null,
            "pickup_type": null,
            "created_at": "2015-10-14T15:42:57.705Z",
            "updated_at": "2015-10-14T15:42:57.705Z",
        }
    ],
    "meta": {
        "next": "http://transit.land/api/v1/schedule_stop_pairs?offset=2&per_page=1",
        "offset": 1,
        "per_page": 1,
        "prev": "http://transit.land/api/v1/schedule_stop_pairs?offset=0&per_page=1",
        "total": 2817329
    }    
}
````
