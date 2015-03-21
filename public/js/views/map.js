var DeveloperPlayground = DeveloperPlayground || {};

DeveloperPlayground.MapView = Backbone.View.extend({
    el: '#map-view',

    // initialize: function () {
        
    // },

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
        L.tileLayer('https://{s}.tiles.mapbox.com/v3/randyme.4d62ee7c/{z}/{x}/{y}.png', {maxZoom: 18})
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
        // console.log("addPoint");
        // stop.attributes.operators_serving_stop.each(console.log("operator serving stop: ", onestop_id));
        // console.log("operaters serving stop: ", stop.attributes.operators_serving_stop);
        if (stop.get('display') !== false) {
            var s = {'type': 'Feature', 'geometry':stop.attributes.geometry};
            L.geoJson(s, {
                color: '#dd339c',
                opacity: 1,
                weight: 3,
            }).addTo(this.featuregroup);
        }

        // apply styling here ^^
        return this;
    },

    addFeatureGroup: function() {
        console.log("addFeatureGroup");
        this.featuregroup.addTo(this.map);
        this.map.fitBounds(this.featuregroup.getBounds());
    }

});



