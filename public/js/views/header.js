var DeveloperPlayground = DeveloperPlayground || {};

DeveloperPlayground.HeaderView = Backbone.View.extend({
	el: 'table#table-view thead',
    templateStopHeader: _.template( $('#stop-header-template').html() ),
    templateOperatorHeader: _.template( $('#operator-header-template').html() ),
    templateRouteHeader: _.template( $('#routes-header-template').html() ),
		
	initialize: function() {
		// console.log("headerView initialized");
        this.render();
	},
	
	render: function() {


		if (this.collection instanceof DeveloperPlayground.Stops) {
			this.$el.html(this.templateStopHeader());
			return this;
		} else if (this.collection instanceof DeveloperPlayground.Operators) {
			this.$el.html(this.templateOperatorHeader());
			return this;
		} else if (this.collection instanceof DeveloperPlayground.Routes) {
			this.$el.html(this.templateRouteHeader());
			return this;
		}
	},

});




