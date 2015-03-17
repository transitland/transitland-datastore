var DeveloperPlayground = DeveloperPlayground || {};

DeveloperPlayground.Operator = Backbone.Model.extend();

DeveloperPlayground.Operators = Backbone.Collection.extend({
	model: DeveloperPlayground.Operator,
	
	setQueryParameters: function(queryParameters) {
		this.url = queryParameters.url;
        console.log("url: ", this.url);
	},
	
	parse: function(response, xhr) {
		return response.operators;
	}
});



