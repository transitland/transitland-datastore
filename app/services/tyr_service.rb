# This Ruby script queries the Tyr ("take your route") service
# to associate a latitude-longitude pair with the closest OSM way.
#
# For more information about Tyr, see https://github.com/valhalla/tyr

require 'singleton'

class TyrService
  include Singleton

  BASE_URL = Figaro.env.tyr_service_base_url || 'http://valhalla.api.dev.mapzen.com'

  class Error < StandardError
  end

  def self.locate(locations: [], costing: 'pedestrian')
    response = connection.get('/locate') do |req|
      json_payload = {
        locations: locations,
        costing: costing,
        api_key: Figaro.env.tyr_api_key
      }
      req.params['json'] = JSON.dump(json_payload)
    end

    if response.body.blank?
      raise Error.new('Tyr returned an empty response')
    else
      raw_json = response.body
      parsed_json = JSON.parse(raw_json)
      parsed_json.map(&:deep_symbolize_keys)
    end
  end

  private

  def self.connection
    @conn ||= Faraday.new(url: BASE_URL) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
    @conn
  end
end
