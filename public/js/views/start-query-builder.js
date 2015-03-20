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
            "stops": {
                "": "",
                "map view": "",
                "name": "",
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
            }
        };

        $parameterSelect.empty().append(function() {
            var output = '';
            $.each(selectValues[$entitySelect.val()], function(key, value) {
                output += '<option>' + key + '</option>';
            });
            return output;
        });
    },
    
    changeName: function() {
        var $entitySelect = $('select.form-control#entity');
        var $parameterSelect = $('select.form-control#parameter');
        var $nameSelect = $('select.form-control#name');
        

        if($parameterSelect.val() == "name") {
            // var $entitySelect = $('select.form-control#entity');

            // ********** MOVE COLLECTION SETTING TO CHANGE PARAM FUNCTION ***********
            collection = this.operators;
            // **********************************************
            
            // var entity = $entitySelect.val();
            // console.log("entity: ", entity);
            // collection = entity;
            // console.log("collection: ", collection);

            $(".form-control#name").show();
            this.nameListView = new DeveloperPlayground.NameListView({collection: collection});
            collection.fetch();
            // this.nameListView.selectName();
            return this;
        } else {
            $(".form-control#name").hide();
            this.nameListView.close();
        }

    },

    submit: function() {
        var $entitySelect = $('select.form-control#entity');
        var $parameterSelect = $('select.form-control#parameter');
        var $nameSelect = $('select.form-control#name');
        var bounds = this.mapview.getBounds();
        var identifier = $nameSelect.val();
        console.log("identifier: ", identifier);

        var collection;
        var shouldFetchAndResetCollection = true;

        // FOR STOP QUERIES

        if ($entitySelect.val() == "stops") {
            collection = this.stops;
            // for search by map view
            if($parameterSelect.val() == "map view") {
            this.stops.setQueryParameters({
                    url: '/api/v1/'+$entitySelect.val()+'.json?bbox='+bounds
                });
            // for search by operator name
            } else if($parameterSelect.val() == "name") {
                this.stops.setQueryParameters({
                    url: '/api/v1/'+$entitySelect.val()+'.json?identifier='+identifier,
                });
            }
        
        // FOR OPERATOR QUERIES
        
        } else if ($entitySelect.val() == "operators") {
            collection = this.operators;
            
            if($parameterSelect.val() == "map view") {
                this.operators.setQueryParameters({
                    url: '/api/v1/'+$entitySelect.val()+'.json?bbox='+bounds
                });
            } else if($parameterSelect.val() == "name") {
                this.operators.hideAll();
                this.operators.get(identifier).set({ display: true });
                shouldFetchAndResetCollection = false;
                // this.operators.setQueryParameters({
                //     url: '/api/v1/'+$entitySelect.val()+'/'+identifier,
                // });
            } else {
                alert("Please select either map view or name.");
            }
            
        //  FOR ROUTE QUERIES
        
        } else if ($entitySelect.val() == "routes") {
            collection = this.routes;
            if($parameterSelect.val() == "map view") {
                this.routes.setQueryParameters({
                    url: '/api/v1/'+$entitySelect.val()+'.json?bbox='+bounds
                });
            } else if($parameterSelect.val() == "name") {
                this.routes.setQueryParameters({
                    url: '/api/v1/'+$entitySelect.val()+'.json?identifier='+identifier,
                });
            } else if($parameterSelect.val() == "route number") {
                alert("routes by route number not yet functional");
            }
        } else {
            alert("Please select a parameter.");
        }

        if (shouldFetchAndResetCollection) {
            collection.reset();
        }

        this.mapview.featuregroup.clearLayers();
        this.mapview.setCollection({collection: collection});
        this.mapview.initialize({collection: collection});

        if ('undefined' !== typeof this.tableview) this.tableview.close();

        this.tableview = new DeveloperPlayground.TableView({collection: collection});
        this.headerView = new DeveloperPlayground.HeaderView({collection: collection});

        if (shouldFetchAndResetCollection) {
            collection.fetch();
        }

    },
});