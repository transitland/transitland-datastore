var DeveloperPlayground = DeveloperPlayground || {};

DeveloperPlayground.NameView = Backbone.View.extend({
	tagName: 'option',
	template: _.template( $('#name-template').html() ),

	render: function() {
		this.$el.get('name');
		renderedHtml = this.template(this.model.toJSON());
		this.$el.html(renderedHtml);
		this.$el.val(this.model.get('onestop_id'));
		return this;
	},

 });




