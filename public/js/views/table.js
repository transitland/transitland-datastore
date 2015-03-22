var DeveloperPlayground = DeveloperPlayground || {};

DeveloperPlayground.TableView = Backbone.View.extend({
    el: 'table#table-view',

    initialize:function(options){
        this.collection = options.collection;
        this.listenTo(this.collection, 'add', this.renderRow);
        // this.render();
    },

    renderRow: function(model) {
        var rowView = new DeveloperPlayground.RowView({
            model: model
        });
        $("tbody", this.$el).append(rowView.render().$el);
    },

    close: function() {
        $('thead, tbody', this.$el).empty();
        this.stopListening();
        return this;
    },

    // render: function (options){

    //     var columns = [{
    //         name: "id", // The key of the model attribute
    //         label: "ID", // The name to display in the header
    //         editable: false, // By default every cell in a column is editable, but *ID* shouldn't be
    //         // Defines a cell type, and ID is displayed as an integer without the ',' separating 1000s.
    //         cell: Backgrid.IntegerCell.extend({
    //           orderSeparator: ''
    //         })
    //           }, {
    //             name: "name",
    //             label: "Name",
    //             // The cell type can be a reference of a Backgrid.Cell subclass, any Backgrid.Cell subclass instances like *id* above, or a string
    //             cell: "string" // This is converted to "StringCell" and a corresponding class in the Backgrid package namespace is looked up
    //           }, {
    //             name: "onestop_id",
    //             label: "onestop_id",
    //             cell: "string" // This is converted to "StringCell" and a corresponding class in the Backgrid package namespace is looked up
    //       }];

    //     // Initialize a new Grid instance
    //     var grid = new Backgrid.Grid({
    //       columns: columns,
    //       collection: this.collection
    //     });
        
    //     // Render the grid and attach the root to your HTML document
    //     $(".backgrid-container#example-1-result").append(grid.render().el);
    // }

});

