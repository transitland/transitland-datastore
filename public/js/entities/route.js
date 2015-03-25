var DeveloperPlayground = DeveloperPlayground || {};

DeveloperPlayground.Route = Backbone.Model.extend();

DeveloperPlayground.Routes = Backbone.Collection.extend({
	model: DeveloperPlayground.Route,
	url: '/api/v1/routes.json',
	
	setQueryParameters: function(queryParameters) {
		this.identifier = queryParameters.identifier;
		this.url = queryParameters.url;
        console.log("url: ", this.url);
	},
	
	parse: function(response, xhr) {
		return response.routes;
	}
});


