var DeveloperPlayground = DeveloperPlayground || {};

DeveloperPlayground.MapView = Backbone.View.extend({
    el: '#map-view',

    events: {
        'click #map-view' : 'getBounds'
    },

    setCollection: function(options){
        this.collection = options.collection;
        console.log("setCollection: ", this.collection);
        this.listenTo(this.collection, 'add', this.addFeature);
        this.listenTo(this.collection, 'sync', this.addFeatureGroup);
        this.collection.each(this.addFeature, this);
        if (this.collection.length > 0) {
            this.addFeatureGroup();
        }
    },
    
    render: function() {
        // this.featuregroup = new L.featureGroup();
        this.markerclustergroup = new L.MarkerClusterGroup({
            maxClusterRadius: 120,
            iconCreateFunction: function (cluster) {
                var markers = cluster.getAllChildMarkers();
                var n = 0;
                for (var i = 0; i < markers.length; i++) {
                    n += markers[i].number;
                }
                return L.divIcon({ html: n, className: 'mycluster', iconSize: L.point(40, 40) });
            }
        });
        this.map = L.map('map-view').setView([37.749, -122.443], 9);
        L.tileLayer('https://{s}.tiles.mapbox.com/v3/randyme.4d62ee7c/{z}/{x}/{y}.png', {
            maxZoom: 18,
            attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
        })
            .addTo(this.map);
        return this;
    },

    getBounds: function() {
        this.bounds=this.map.getBounds();
        this.bBoxString=this.bounds.toBBoxString();
        return this.bBoxString;
    },

    addFeature: function(feature) {
        this.collection = feature.collection;

        if (feature.get('display') !== false) {
            var s = {
                'type': 'Feature',
                'name': feature.attributes.name,
                'geometry':feature.attributes.geometry,
            };
            L.geoJson(s, {
                onEachFeature: this.onEachFeature,
                style: this.styleEachFeature
            })
            // .addTo(this.featuregroup);
            .addTo(this.markerclustergroup);

        }

        return this;
    },

    styleEachFeature: function(feature) {

        var operatorStyle = {
            color: "#dd339c",
            fillColor: "#dd339c",
            weight: 3,
            opacity: .8,
            fillOpacity: .3,
            className: 'blah'
        };

        var routeStyle = {
            color: "#7720f2",
            weight: 3,
            opacity: 1,
            className: 'blah'
        };

        var geom_type = feature.geometry.type.toLowerCase();
       
        if ( geom_type === 'polygon') {
            return operatorStyle;
        } else if (geom_type == 'point') {
            return {};
        } else if (geom_type.indexOf('line') !== -1) {
            // styles.color = "#f34";
            return routeStyle;
        }
        return {};
    },

    onEachFeature: function(feature, layer) {

        var stopIcon = L.icon({
            iconUrl: "/assets/images/dot2a.png",
            iconSize:     [15, 15], // size of the icon
            iconAnchor:   [5, 5], // point of the icon which will correspond to marker's location
            popupAnchor:  [5, 5] // point from which the popup should open relative to the iconAnchor
        });

        var geom_type = feature.geometry.type.toLowerCase();

        if (geom_type == 'point') {
            layer.setIcon(stopIcon);
        }

        layer.bindPopup(feature.name);
    },


    addFeatureGroup: function() {
        console.log('add');
        // this.featuregroup.addTo(this.map);
        this.markerclustergroup.addTo(this.map);
        // this.map.fitBounds(this.featuregroup.getBounds());
        this.map.fitBounds(this.markerclustergroup.getBounds());

    }

});



