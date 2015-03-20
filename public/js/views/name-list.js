var DeveloperPlayground = DeveloperPlayground || {};

DeveloperPlayground.NameListView = Backbone.View.extend({
	el: '.btn-group#nameMenu',

	initialize:function(options){
        this.collection = options.collection;
        this.listenTo(this.collection, 'add', this.renderName);
        this.collection.each(this.renderName, this);
    },

    renderName: function(model) {
        var nameView = new DeveloperPlayground.NameView({
            model: model
        });
        $(".form-control#name", this.$el).append(nameView.render().$el);
    },

    selectName: function(model) {
		this.$el.val();
		console.log("selectName val: ", this.$el.val());
		return this;
    },

    close: function() {
        $('.form-control#name', this.$el).empty();
        this.stopListening();
        return this;
    }

});