var DeveloperPlayground = DeveloperPlayground || {};

DeveloperPlayground.TableView = Backbone.View.extend({
    el: 'table#table-view',

    initialize:function(options){
        this.collection = options.collection;
        // $("tbody", this.$el).empty(this.$el);
        this.listenTo(this.collection, 'add', this.renderRow);
        // this.listenTo(this.collection, 'change', this.close);
        // new:
        // this.listenTo(this.collection, 'remove', this.clearRows);
        // 
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
    }

});

