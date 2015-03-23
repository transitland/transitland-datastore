var DeveloperPlayground = DeveloperPlayground || {};

DeveloperPlayground.GridView = Backbone.View.extend({
    el: '.backgrid-container',

    initialize:function(options){
        this.collection = options.collection;
        this.listenTo(this.collection, 'sync', this.render);
    },

    render: function(model){

        var columns;
        var grid;
        var $entitySelect = $('select.form-control#entity');


        if ($entitySelect.val() == "operators"){

            columns = [{
                name: "id",
                label: "ID",
                renderable: false,
                editable: false,
                cell: Backgrid.IntegerCell.extend({
                  orderSeparator: ''
                })
              }, {
                name: "onestop_id",
                label: "OneStop ID",
                editable: false,
                cell: "string"
              }, {
                name: "name",
                label: "Operator name",
                editable: false,
                cell: "string"
              // }, {
              //   name: "website",
              //   label: "Operator website",
              //   editable: false,
              //   // The cell type can be a reference of a Backgrid.Cell subclass, any Backgrid.Cell subclass instances like *id* above, or a string
              //   cell: "string" // This is converted to "StringCell" and a corresponding class in the Backgrid package namespace is looked up
            }];
            grid = new Backgrid.Grid({
            columns: columns,
            collection: this.collection
            });
            $("#results").append(grid.render().$el);
        } else if ($entitySelect.val() == "stops"){
            columns = [{
                name: "id",
                label: "ID",
                renderable: false,
                editable: false,
                cell: Backgrid.IntegerCell.extend({
                  orderSeparator: ''
                })
              }, {
                name: "name",
                label: "Stop name",
                editable: false,
                cell: "string"
              }, {
                name: "onestop_id",
                label: "OneStop ID",
                editable: false,
                cell: "string"
            }];

            grid = new Backgrid.Grid({
            columns: columns,
            collection: this.collection
            });
            $("#results").append(grid.render().$el);
        } else if ($entitySelect.val() == "routes"){
            columns = [{
                name: "id",
                label: "ID",
                renderable: false,
                editable: false,
                cell: Backgrid.IntegerCell.extend({
                  orderSeparator: ''
                })
              }, {
                name: "onestop_id",
                label: "OneStop ID",
                editable: false,
                cell: "string"
              }, {
                name: "name",
                label: "Route name",
                editable: false,
                cell: "string"
            }];

            grid = new Backgrid.Grid({
            columns: columns,
            collection: this.collection
            });
            $("#results").append(grid.render().$el);
        }

    },

    close: function() {
        $(this.$el).empty();
        this.stopListening();
        return this;
    }

});

