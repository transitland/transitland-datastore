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
        $(".form-control#operator-name").hide();
        this.mapview = new DeveloperPlayground.MapView();
        this.mapview.render();
        return this;
    },

    changeParam: function() {
        var $entitySelect = $('select.form-control#entity');
        var $parameterSelect = $('select.form-control#parameter');
        var selectValues = {
            "stops": {
                "": "",
                "map view": "",
                "name": "",
                // "mode": "",
            },
            "operators": {
                "": "",
                "map view": "",
                "name": "",
                // "mode": "",
            },
            "routes": {
                "": "",
                "map view": "",
                "name": "",
                "route number": "",
                // accept typed search on string for name/identifier:
                // "name": "",
                // "mode": "",
            }
        };

        if($parameterSelect.val() != "name") {
            $(".form-control#operator-name").hide();
        }

        $parameterSelect.empty().append(function() {
            var output = '';
            $.each(selectValues[$entitySelect.val()], function(key, value) {
                output += '<option>' + key + '</option>';
            });
            return output;
        });
    },
    
    changeName: function() {
        var $parameterSelect = $('select.form-control#parameter');
        var $nameSelect = $('select.form-control#operator-name');

        // 
        // ***** Populate selectName list using operator query?
        // 
        var selectName = {
            "name": {
                "": "",
                "AC Transit": "",
                "BART": "",
                "Muni": "",
                "SamTrans": "",
                "VTA": "",
            }
        };
        // 
        // 
        // 

        if($parameterSelect.val() == "name") {
            $(".form-control#operator-name").show();
        } else {
            $(".form-control#operator-name").hide();
        }
    
        $nameSelect.empty().append(function() {
            var output = '';
            $.each(selectName[$parameterSelect.val()], function(key, value) {
                output += '<option>' + key + '</option>';
            });
            return output;
        });
    },

    submit: function() {
        var $entitySelect = $('select.form-control#entity');
        var $parameterSelect = $('select.form-control#parameter');
        var $nameSelect = $('select.form-control#operator-name');
        var bounds = this.mapview.getBounds();
        var identifier = $nameSelect.val();
        var collection;

        // FOR STOP QUERIES

        if ($entitySelect.val() == "stops") {
            collection = this.stops;
            // for search by map view
            if($parameterSelect.val() == "map view") {
            this.stops.setQueryParameters({
                    url: 'http://localhost:4567/api/v1/'+$entitySelect.val()+'.json?bbox='+bounds
                });
            // for search by operator name
            } else if($parameterSelect.val() == "name") {
                this.stops.setQueryParameters({
                    url: 'http://localhost:4567/api/v1/'+$entitySelect.val()+'.json?identifier='+identifier,
                });
            }
        
        // FOR OPERATOR QUERIES
        
        } else if ($entitySelect.val() == "operators") {
            collection = this.operators;
            if($parameterSelect.val() === "") {
                this.operators.setQueryParameters({
                    url: 'http://localhost:4567/api/v1/'+$entitySelect.val()+'.json'
                });
            }
            else if($parameterSelect.val() == "map view") {
                this.operators.setQueryParameters({
                    url: 'http://localhost:4567/api/v1/'+$entitySelect.val()+'.json?bbox='+bounds
                });
            } else if($parameterSelect.val() == "name") {
                this.operators.setQueryParameters({
                    url: 'http://localhost:4567/api/v1/'+$entitySelect.val()+'.json?identifier='+identifier,
                });
            }
            // for search by mode
            // } else if($parameterSelect.val() == "mode") {
            //     alert("operators by mode not yet functional");
            // }

        //  FOR ROUTE QUERIES
        
        } else if ($entitySelect.val() == "routes") {
            collection = this.routes;
            if($parameterSelect.val() == "map view") {
                this.routes.setQueryParameters({
                    url: 'http://localhost:4567/api/v1/'+$entitySelect.val()+'.json?bbox='+bounds
                });
            } else if($parameterSelect.val() == "name") {
                this.routes.setQueryParameters({
                    url: 'http://localhost:4567/api/v1/'+$entitySelect.val()+'.json?identifier='+identifier,
                });
            // for search by mode
            } else if($parameterSelect.val() == "route number") {
                alert("routes by route number not yet functional");
            // } else if($parameterSelect.val() == "mode") {
            //     alert("routes by mode not yet functional");
            }
        } else {
            alert("please select a parameter");
        }

        collection.fetch();

        this.mapview.setCollection({collection: collection});
        this.mapview.featuregroup.clearLayers();
        this.mapview.initialize({collection: collection});

        if ('undefined' !== typeof this.tableview) this.tableview.close();

        this.tableview = new DeveloperPlayground.TableView({collection: collection});
        this.headerView = new DeveloperPlayground.HeaderView({collection: collection});

    },


});