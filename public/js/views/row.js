var DeveloperPlayground = DeveloperPlayground || {};

DeveloperPlayground.RowView = Backbone.View.extend({
	tagName: 'tr',
	templateStop: _.template( $('#stop-template').html() ),
	templateOperator: _.template( $('#operator-template').html() ),
	
	initialize: function() {
		// console.log("rowView initialized");
		this.listenTo(this.model, 'remove', this.close);
	},
	
	render: function() {
		if (this.model instanceof DeveloperPlayground.Stop) {
			renderedHtml = this.templateStop(this.model.toJSON());
			this.$el.html(renderedHtml);
			return this;
		} else if (this.model instanceof DeveloperPlayground.Operator) {
			renderedHtml = this.templateOperator(this.model.toJSON());
			this.$el.html(renderedHtml);
			return this;
		} else {
			// console.log("instanceof not working");
		}
	},


 });




