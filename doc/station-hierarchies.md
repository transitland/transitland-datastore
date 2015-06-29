# Station Hierarchies

The Transitland Datastore uses a hierarchy to model the fixed facilities that riders use to access transit service. 

Every `Station` object is associated with a minimum of:

- one `StationEgress` object, which connects to the OpenStreetMap pedestrian network
- one `StationPlatform` object, which is served by `Operator` and `Route`objects


Multiple `StationEgress` and `StationPlatforms` can be combined to model more complex situations. For example:

- bus stops on opposite sides of a street (a `Station` object, with two `StationEgress`'s and two `StationPlatform`'s)
- underground subway stops with multiple entrance/exit points (a `Station` object, with multiple `StationEgress`'s)
- intermodal stations with train tracks and bus bays served by different operators (a `Station` object with multiple `StationPlatform`'s)

`Station`, `StationEgress`, and `StationPlatform` can each be assigned a name, identifiers, tags, and a geometry.

## Diagram of Models and Associations

````
   +-----------------------------------+
   |Station                            |
   |-----------------------------------|
   |- onestop_id "s-9q8yy-Civic~Center"|
   |- name                             |
   |- identifiers                      |
   |- tags                             |
   |- geometry                         |
   +-----------------------------------+
     ^ ^
     | |    +----------------------------------------------+
     | |    |StationEgress                                 |
     | |    |----------------------------------------------|
     | |    |- onestop_id "s-9q8yy-Civic~Center>8th~Market"|
     | |    |- connected_osm_way_ids                       |-------------> OpenStreetMap
     | |    |- name                                        |               pedestrian
     | |    |- identifiers                                 |               network
     | |    |- tags                                        |
     | +----|- station_id                                  |
     |      +----------------------------------------------+
     |
     |      +-------------------------------------+
     |      |StationPlatform                      |
     |      |-------------------------------------|
     |      |- onestop_id "s-9q8yy-Civic~Center<2"|
     |      |- name                               |<--------------+ OperatorServingPlatform
     |      |- identifiers                        |
     |      |- tags                               |<--------------+ RouteServingPlatform
     +------|- station_id                         |
            |- geometry                           |                 and other service/schedule
            +-------------------------------------+                 models in Datastore
````

## Using Onestop IDs to Refer to Egresses and Platforms

An optional fourth component of a Onestop ID can be used to refer to a `StationEgress` or `StationPlatform`.

To refer to an egress, use a `>`.

To refer to a platform, use a `<`.

For example:

- `s-9q8yy-Civic~Center>8th~Market` to refer to Civic Center Station's egress at 8th and Market.
- `s-9q8yy-Civic~Center<2` to refer to Platform #2 at Civic Center Station.
