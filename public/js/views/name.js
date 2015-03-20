var DeveloperPlayground = DeveloperPlayground || {};

DeveloperPlayground.NameView = Backbone.View.extend({
	tagName: 'option',
	template: _.template( $('#name-template').html() ),

	
	initialize: function() {
		// console.log("rowView initialized");
		// this.listenTo(this.model, 'remove', this.close);
		// _.bindAll(this, 'render');
	},
	
	render: function() {
		this.$el.get('name');
		console.log("rendering nameview: ", this.model.get('name'));
		// return this;
		renderedHtml = this.template(this.model.toJSON());
		this.$el.html(renderedHtml);
		this.$el.val(this.model.get('onestop_id'));
		return this;
	},

 });




