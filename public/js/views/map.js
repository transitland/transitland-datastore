var DeveloperPlayground = DeveloperPlayground || {};

DeveloperPlayground.MapView = Backbone.View.extend({
    el: '#map-view',

    events: {
        'click #map-view' : 'getBounds'
    },

    setCollection: function(options){
        this.collection = options.collection;
        console.log("setCollection: ", this.collection);
        this.listenTo(this.collection, 'add', this.addPoint);
        this.listenTo(this.collection, 'sync', this.addFeatureGroup);
        this.collection.each(this.addPoint, this);
        if (this.collection.length > 0) {
            this.addFeatureGroup();
        }
    },
    
    render: function() {
        // console.log("render map");
        this.featuregroup = new L.featureGroup();
        this.map = L.map('map-view').setView([37.749, -122.443], 9);
        L.tileLayer('https://{s}.tiles.mapbox.com/v3/randyme.4d62ee7c/{z}/{x}/{y}.png', {
            maxZoom: 18,
            attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
        })
            .addTo(this.map);
        return this;
    },

    getBounds: function() {
        // console.log("getbounds");
        this.bounds=this.map.getBounds();
        this.bBoxString=this.bounds.toBBoxString();
        return this.bBoxString;
    },

    addPoint: function(stop) {
        console.log("addPoint");
        var stopIcon = L.icon({
            iconUrl: "/assets/images/dot2a.png",
            iconSize:     [38, 95], // size of the icon
            iconAnchor:   [22, 94], // point of the icon which will correspond to marker's location
            popupAnchor:  [-3, -76] // point from which the popup should open relative to the iconAnchor
        });
        if (stop.get('display') !== false) {
            var s = {
                'type': 'Feature',
                'geometry':stop.attributes.geometry,
                // 'icon': this.stopIcon,
                // 'properties':{
                //     'icon': {
                //         'title': "stop-marker",
                //         'iconUrl': "/assets/images/dot2a.png",
                //         'iconSize': [50, 50],
                //         'iconAnchor': [25, 25],
                //         'popupAnchor': [25, 25]
                //     }
                // }
            };
            L.geoJson(s, {
                icon: stopIcon,
                color: '#dd339c',
                opacity: 1,
                weight: 3,
            }).addTo(this.featuregroup);
        }

        return this;
    },

    //  addPoint: function(stop) {
    //     var markers = L.markerClusterGroup();

    //     if (stop.get('display') !== false) {
    //         var s = {'type': 'Feature', 'geometry':stop.attributes.geometry};
    //         var marker = L.marker(new L.LatLng(stop.attributes.geometry.coordinates[1], stop.attributes.geometry.coordinates[0]));
    //         // marker.bindPopup(title);
    //         markers.addLayer(marker);
    //     }
    //     this.map.addLayer(markers);
    //     return this;
    // },


    addFeatureGroup: function() {
        // this.featuregroup.
        this.featuregroup.addTo(this.map);
        this.map.fitBounds(this.featuregroup.getBounds());
    }

});



