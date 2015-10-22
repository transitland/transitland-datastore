# Transitland schedule API

Each ScheduleStopPair represents an edge between two stops, made on a particular route, at a particular time

## ScheduleStopPair Data Model

| Attribute                    | Description |
|------------------------------|-------------|
| route_onestop_id             | Route Onestop ID |
| operator_onestop_id          | Operator Onestop ID |
| origin_onestop_id            | Origin Stop Onestop ID |
| origin_timezone              | Origin Stop timezone |
| origin_arrival_time          | Time vehicle arrives at origin from previous stop |
| origin_departure_time        | Time vehicle leaves origin |
| origin_timepoint_source      | Timepoint is exact or interpolated |
| destination_onestop_id       | Destination Stop Onestop ID |
| destination_timezone         | Destination Stop timezone |
| destination_arrival_time     | Time vehicle arrives at destination |
| destination_departure_time   | Time vehicle leaves destination for next stop |
| destination_timepoint_source | Timepoint is exact or interpolated |
| window_start                 | The previous known exact timepoint |
| window_end                   | The next known exact timepoint |
| trip                         | A text label for a sequence of edges |
| trip_headsign                | A human friendly description of the ultimate destination |
| trip_short_name              | A commonly known human-readable trip identifier, e.g. a train number |
| block_id                     | A block of trips made by the same vehicle |
| service_start_date           | Date service begins |
| service_end_date             | Date service ends |
| service_days_of_week         | Scheduled service, in ISO order (Monday -> Sunday) |
| service_added_dates          | Array of additional dates service is scheduled |
| service_except_dates         | Array of dates service is NOT scheduled (Holidays, etc.) |
| wheelchair_accessible        | Wheelchair accessibility |
| bikes_allowed                | Bike accessible |
| drop_off_type                | Regularly scheduled stop for dropping off passengers |
| pickup_type                  | Regularly scheduled stop for picking up passengers |

## Query parameters

The main ScheduleStopPair API endpoint is [/api/v1/schedule_stop_pairs](http://transit.land/api/v1/schedule_stop_pairs). It accepts the following query parameters, which may be freely combined.

| Query parameter        | Description |
|------------------------|-------------|
| [origin_onestop_id](http://dev.transit.land/api/v1/schedule_stop_pairs?origin_onestop_id=s-9q8znb12j1-embarcadero) | Origin Stop |
| [destination_onestop_id](http://dev.transit.land/api/v1/schedule_stop_pairs?destination_onestop_id=s-9q8yyxq427-montgomeryst) | Destination Stop |
| [route_onestop_id](http://dev.transit.land/api/v1/schedule_stop_pairs?route_onestop_id=r-9q8y-n) | Route |
| [operator_onestop_id](http://dev.transit.land/api/v1/schedule_stop_pairs?operator_onestop_id=o-9q9-bart) | Operator |  |
| [date](http://dev.transit.land/api/v1/schedule_stop_pairs?date=2015-08-21) | Service operates on a date |
| [service_from_date](http://dev.transit.land/api/v1/schedule_stop_pairs?service_from_date=2015-10-21) | Service operates on a date, or in the future |
| [origin_departure_between](http://dev.transit.land/api/v1/schedule_stop_pairs?origin_departure_between=09:00:00,09:10:00) | Origin departure time between two times |
| [trip](http://dev.transit.land/api/v1/schedule_stop_pairs?trip=03SFO11SUN) | Trip identifier |
| [bbox](http://dev.transit.land/api/v1/schedule_stop_pairs?bbox=-122.4,37.7,-122.4,30.8) | Origin Stop within bounding box |

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
            "wheelchair_accessible": 0,
            "bikes_allowed": null,
            "drop_off_type": 0,
            "pickup_type": 0,
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
