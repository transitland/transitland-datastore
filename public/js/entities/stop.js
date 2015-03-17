var DeveloperPlayground = DeveloperPlayground || {};

DeveloperPlayground.Stop = Backbone.Model.extend();

DeveloperPlayground.Stops = Backbone.Collection.extend({
	model: DeveloperPlayground.Stop,
	setQueryParameters: function(queryParameters) {
		this.identifier = queryParameters.identifier;
		this.url = queryParameters.url;
        console.log("url: ", this.url);
	},
	
	parse: function(response, xhr) {
		return response.stops;
	}
});


