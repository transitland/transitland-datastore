class Api::V1::ApiV1Controller < Api::V1::BaseApiController
  def index
    json = Rails.cache.fetch('API_V1_JSON_RESPONSE', expires_in: 1.day) do
      {
        api: {
          base_url: api_v1_url,
          documentation: 'https://transit.land/documentation/datastore/api-endpoints.html',
          swagger_description_url: 'https://github.com/transitland/transitland/issues/33', # TODO:
          endpoints: array_of_endpoints
        },
      }
    end

    render json: json
  end

  private

  def array_of_endpoints
    # based on http://stackoverflow.com/a/19627954/40956
    routes = []
    Rails.application.routes.routes.each do |route|
      path = route.path.spec.to_s
      next unless path.starts_with?('/api/v1/')
      path.gsub!(/\(\.:format\)/, "").gsub!('/api/v1', '')
      verb = %W{ GET POST PUT PATCH DELETE }.grep(route.verb).first.downcase.to_sym
      routes << { path: path, verb: verb }
    end
    routes
  end
end
