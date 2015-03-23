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
        this.bounds=this.map.getBounds();
        this.bBoxString=this.bounds.toBBoxString();
        return this.bBoxString;
    },

    addFeature: function(feature) {
        // var $entitySelect = $('select.form-control#entity');
        this.collection = feature.collection;

        console.log("addFeature");
        
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
            .addTo(this.featuregroup);
        }

        return this;
    },

    styleEachFeature: function(feature) {
        var stopIcon = L.icon({
            iconUrl: "/assets/images/dot2a.png",
            iconSize:     [15, 15], // size of the icon
            iconAnchor:   [5, 5], // point of the icon which will correspond to marker's location
            popupAnchor:  [5, 5] // point from which the popup should open relative to the iconAnchor
        });

        var styles = {
            color: "#f00",
            fillColor: "#000",
            weight: 10,
            opacity: 1,
            fillOpacity: 1,
            className: 'blah'
            // icon: stopIcon,
        };

        var geom_type = feature.geometry.type.toLowerCase();
        if ( geom_type === 'polygon') {
            return styles;
        } else if (geom_type == 'point') {
            return {};
        } else if (geom_type.indexOf('line') !== -1) {
            styles.color = "#f34";
            return styles;
        }
        return {};
    },

    onEachFeature: function(feature, layer) {

        // this.collection = feature.collection;
        // console.log("collection: ",this.collection);

        var stopIcon = L.icon({
            iconUrl: "/assets/images/dot2a.png",
            iconSize:     [15, 15], // size of the icon
            iconAnchor:   [5, 5], // point of the icon which will correspond to marker's location
            popupAnchor:  [5, 5] // point from which the popup should open relative to the iconAnchor
        });

        // var $entitySelect = $('select.form-control#entity');
        // console.log("$entitySelect: ",this.$entitySelect);

        var geom_type = feature.geometry.type.toLowerCase();
        if ( geom_type === 'polygon') {
            layer.bindPopup('operator');
        } else if (geom_type == 'point') {
            layer.bindPopup('stop');
            layer.setIcon(stopIcon);
        } else if (geom_type.indexOf('line') !== -1) {
            layer.bindPopup('route');
        }
    
        console.log('feature');
        console.log(feature);
        console.log('layer type');
        console.log(typeof layer);

    },


    addFeatureGroup: function() {
        this.featuregroup.addTo(this.map);
        this.map.fitBounds(this.featuregroup.getBounds());
    }

});



