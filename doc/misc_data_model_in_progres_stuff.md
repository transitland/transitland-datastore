
type of entity | entities | identifier(s) | actions
-------------- | ------- | ------------- | -------
Onestop entities | <ul><li>Operator</li><li>Feed</li><li>Stop</li><li>Route</li></ul> | Onestop ID  | <ul><li>create</li><li>edit</li><li>destroy</li></ul>
internal Transitland entities | <ul><li>OperatorServingStop</li><li>RouteServingStop</li><li>TripSeries + TripSeriesServingStop</li><li>TripSeries + Trip + StopTime</li></ul> | <ul><li>Onestop ID for "left" side</li><li>Onestop ID for "right" side</li><li>attributes</li></ul> | <ul><li>create if doesn't already exist</li><li>delete if already exists</li></ul>


<script src="https://cdn.rawgit.com/knsv/mermaid/0.3.3/dist/mermaid.full.js"></script>

<div class="mermaid">
  graph LR
    Operator-->OperatorServingStop
    OperatorServingStop-->Stop
    Operator-->Route
    Route-->RouteServingStop
    RouteServingStop-->Stop
    Route-->TripSeries
    TripSeries-->TripSeriesServingStop
    TripSeriesServingStop-->Stop
    TripSeries-->Trip
    Trip-->StopTime
    StopTime-->Stop
</div>
