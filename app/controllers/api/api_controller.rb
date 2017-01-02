class Api::ApiController < Api::V1::BaseApiController
  def index
    json = Rails.cache.fetch('API_JSON_RESPONSE', expires_in: 1.day) do
      version = TransitlandDatastore::Application::VERSION
      {
        datastore: {
          version: version,
          documentation: 'https://transit.land/documentation/datastore/',
          code: "https://github.com/transitland/transitland-datastore/tree/#{version}",
          release_notes: "https://github.com/transitland/transitland-datastore/releases/tag/#{version}"
        },
        api_versions: {
          v1: {
            base_url: api_v1_url,
            kind: Api::V1::BaseApiController::API_KIND
          }
        }
      }
    end

    render json: json
  end
end
