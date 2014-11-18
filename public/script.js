(function () {

  // zoom level set to 1 due to leaflet bugginess -- maptiles don't refresh after fitBounds without setting zoom level this way.
  var map = L.map('stopMap').setView([37.749, -122.443], 1);

  var stopTiles = L.tileLayer('https://{s}.tiles.mapbox.com/v3/randyme.k5036ipp/{z}/{x}/{y}.png', {
    maxZoom: 18
  });

  stopTiles.addTo(map);

  var markers = new L.MarkerClusterGroup();


  function popUp(feature, layer) {
    // layer.bindPopup("Stop name: "+feature.properties.name+
    //                 "<br/>ID: "+feature.id+
    //                 "<br/>Indentifier: "+feature.properties.identifiers.identifier+
    //                 "<br/>Coordinates: "+feature.geometry.coordinates+
    //                 "<br/>Tags: "+feature.properties.tags+
    //                 "<br/>GTFS_Column: "+feature.properties.identifiers[0].tags.gtfs_column+
    //                 "<br/>GTFS_Source: "+feature.properties.identifiers[0].tags.gtfs_source);
    layer.bindPopup(JSON.stringify(feature, {
      }));
  }

  function getStops(){
    var mapExtent = map.getBounds();
    var swLng = mapExtent._southWest.lng;
    var swLat = mapExtent._southWest.lat;
    var neLng = mapExtent._northEast.lng;
    var neLat = mapExtent._northEast.lat;
    
    console.log(swLng, swLat, neLng, neLat);
    console.log(mapExtent);

    var geojsonLayer = new L.GeoJSON.AJAX("/api/v1/stops.geojson?bbox="+swLng+","+swLat+","+neLng+","+neLat, {onEachFeature:popUp});

    geojsonLayer.on('data:loaded',function(e){
        markers.addLayer(geojsonLayer);
        markers.addTo(map);
    });
  }

  function removeMarkers(e){
    markers.clearLayers();
  }

  $(document).ready(function () {
    $(".getStops").click(function(e){
      removeMarkers();
      getStops();
    });
  });

})();