var DeveloperPlayground = DeveloperPlayground || {};

DeveloperPlayground.StartQueryBuilderView = Backbone.View.extend({
    el: "#developer-playground",

    template: _.template($('#playground-template').html()),


    events: {
        'change .form-control#entity': 'changeParam',
        'change .form-control#parameter': 'changeName',
        'click .btn' : 'submit',
    },


    initialize: function () {
        this.operators = new DeveloperPlayground.Operators();
        this.stops = new DeveloperPlayground.Stops();
        this.routes = new DeveloperPlayground.Routes();
        this.render();
    },

    render: function() {
        this.$el.html(this.template());
        $(".form-control#name").hide();
        this.mapview = new DeveloperPlayground.MapView();
        this.mapview.render();
        return this;
    },

    changeParam: function() {

        $(".form-control#name").hide();

        var $entitySelect = $('select.form-control#entity');
        var $parameterSelect = $('select.form-control#parameter');
        var selectValues = {
            "base": {
                "__________": "",
            },
            "stops": {
                "__________": "",
                "map view": "",
                "operator": "",
            },
            "operators": {
                "__________": "",
                "map view": "",
                "name": "",
                // "mode": "",
            },
            "routes": {
                "__________": "",
                "map view": "",
                "operator": "",
                // "route number": "",
            }
        };

        $parameterSelect.empty().append(function() {
            var output = '';
            $.each(selectValues[$entitySelect.val()], function(key, value) {
                output += '<option>' + key + '</option>';
            });
            return output;
        });

        return this;
    },
    
    changeName: function() {
        var $parameterSelect = $('select.form-control#parameter');

        if($parameterSelect.val() == "name" || $parameterSelect.val() == "operator") {
            collection = this.operators;
            $(".form-control#name").show();
            this.nameListView = new DeveloperPlayground.NameListView({collection: collection});
            collection.fetch();
            return this;
        } else {
            $(".form-control#name").hide();
        }

    },

    submit: function() {
        var $entitySelect = $('select.form-control#entity');
        var $parameterSelect = $('select.form-control#parameter');
        var $nameSelect = $('select.form-control#name');
        var bounds = this.mapview.getBounds();
        var identifier = $nameSelect.val();

        console.log("identifier: ", identifier);

        var shouldFetchAndResetCollection = true;

        // FOR STOP QUERIES

        if ($entitySelect.val() == "stops") {
            // for search by map view
            if($parameterSelect.val() == "map view") {
            collection = this.stops;
            this.stops.setQueryParameters({
                    url: '/api/v1/'+$entitySelect.val()+'.json?bbox='+bounds
                });
            // for search by operator name
            } else if($parameterSelect.val() == "operator") {
                collection = this.stops;
                this.stops.setQueryParameters({
                    url: '/api/v1/'+$entitySelect.val()+'.json?operatedBy='+identifier,
                });
                console.log("url: ", this.url);
            }
        
        // FOR OPERATOR QUERIES
        
        } else if ($entitySelect.val() == "operators") {
            
            if($parameterSelect.val() == "map view") {
                collection = this.operators;
                this.operators.setQueryParameters({
                    url: '/api/v1/'+$entitySelect.val()+'.json?bbox='+bounds
                });
            } else if($parameterSelect.val() == "name") {
                console.log("operators by name");
                this.operators.hideAll();
                this.operators.get(identifier).set({ display: true });
                shouldFetchAndResetCollection = false;
            } else {
                alert("Please select either map view or name.");
            }
            
        //  FOR ROUTE QUERIES
        
        } else if ($entitySelect.val() == "routes") {
            if($parameterSelect.val() == "map view") {
                collection = this.routes;
                this.routes.setQueryParameters({
                    url: '/api/v1/'+$entitySelect.val()+'.json?bbox='+bounds
                });
            } else if($parameterSelect.val() == "operator") {
                collection = this.routes;
                this.routes.setQueryParameters({
                    url: '/api/v1/'+$entitySelect.val()+'.json?operatedBy='+identifier,
                });
                console.log("url: ", this.url);
            } else if($parameterSelect.val() == "route number") {
                collection = this.routes;
                alert("routes by route number not yet functional");
            }
        } else {
            alert("Please select a parameter.");
        }

        if (shouldFetchAndResetCollection) {
            collection.reset();
        }

        // this.mapview.featuregroup.clearLayers();
        this.mapview.markerclustergroup.clearLayers();
        this.mapview.setCollection({collection: collection});
        this.mapview.initialize({collection: collection});

        // if ('undefined' !== typeof this.tableview) this.tableview.close();
        if ('undefined' !== typeof this.gridview) this.gridview.close();

        this.gridview = new DeveloperPlayground.GridView({collection: collection});
        


        // this.tableview = new DeveloperPlayground.TableView({collection: collection});
        // this.headerView = new DeveloperPlayground.HeaderView({collection: collection});

        if (shouldFetchAndResetCollection) {
            collection.fetch();
        }

    },
});