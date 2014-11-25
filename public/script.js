(function () {

  var map = L.map('stopMap', {
    minZoom: 10,
    tileLayer: {
      continuousWorld: false,
      noWrap: true
    }
  }).setView([37.749, -122.443], 12);

  var stopTiles = L.tileLayer('https://{s}.tiles.mapbox.com/v3/randyme.k5036ipp/{z}/{x}/{y}.png', {
    maxZoom: 18
  });

  stopTiles.addTo(map);

  var markers = new L.MarkerClusterGroup();


  function popUp(feature, layer) {
    // Change set_show_to_level to "all" to display all json data expanded, or adjust number to desired level
    layer.bindPopup(renderjson.set_show_to_level(2)(feature));
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