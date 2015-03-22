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
                name: "id", // The key of the model attribute
                label: "ID", // The name to display in the header
                editable: false, // By default every cell in a column is editable, but *ID* shouldn't be
                // Defines a cell type, and ID is displayed as an integer without the ',' separating 1000s.
                cell: Backgrid.IntegerCell.extend({
                  orderSeparator: ''
                })
              }, {
                name: "name",
                label: "Operator name",
                editable: false,
                // The cell type can be a reference of a Backgrid.Cell subclass, any Backgrid.Cell subclass instances like *id* above, or a string
                cell: "string" // This is converted to "StringCell" and a corresponding class in the Backgrid package namespace is looked up
              }, {
                name: "onestop_id",
                label: "OneStop ID",
                editable: false,
                cell: "string" // An integer cell is a number cell that displays humanized integers
            }];
            grid = new Backgrid.Grid({
            columns: columns,
            collection: this.collection
            });
            // Render the grid and attach the root to your HTML document
            $("#results").append(grid.render().$el);
        } else if ($entitySelect.val() == "stops"){
            columns = [{
                name: "id", // The key of the model attribute
                label: "ID", // The name to display in the header
                editable: false, // By default every cell in a column is editable, but *ID* shouldn't be
                // Defines a cell type, and ID is displayed as an integer without the ',' separating 1000s.
                cell: Backgrid.IntegerCell.extend({
                  orderSeparator: ''
                })
              }, {
                name: "name",
                label: "Stop name",
                editable: false,
                // The cell type can be a reference of a Backgrid.Cell subclass, any Backgrid.Cell subclass instances like *id* above, or a string
                cell: "string" // This is converted to "StringCell" and a corresponding class in the Backgrid package namespace is looked up
              }, {
                name: "onestop_id",
                label: "OneStop ID",
                editable: false,
                cell: "string" // An integer cell is a number cell that displays humanized integers
            }];

            grid = new Backgrid.Grid({
            columns: columns,
            collection: this.collection
            });
            // Render the grid and attach the root to your HTML document
            $("#results").append(grid.render().$el);
        } else if ($entitySelect.val() == "routes"){
            columns = [{
                name: "id", // The key of the model attribute
                label: "ID", // The name to display in the header
                editable: false, // By default every cell in a column is editable, but *ID* shouldn't be
                // Defines a cell type, and ID is displayed as an integer without the ',' separating 1000s.
                cell: Backgrid.IntegerCell.extend({
                  orderSeparator: ''
                })
              }, {
                name: "name",
                label: "Route name",
                editable: false,
                // The cell type can be a reference of a Backgrid.Cell subclass, any Backgrid.Cell subclass instances like *id* above, or a string
                cell: "string" // This is converted to "StringCell" and a corresponding class in the Backgrid package namespace is looked up
              }, {
                name: "onestop_id",
                label: "OneStop ID",
                editable: false,
                cell: "string" // An integer cell is a number cell that displays humanized integers
            }];

            grid = new Backgrid.Grid({
            columns: columns,
            collection: this.collection
            });
            // Render the grid and attach the root to your HTML document
            $("#results").append(grid.render().$el);
        }

    },

    close: function() {
        $(this.$el).empty();
        this.stopListening();
        return this;
    }

});

