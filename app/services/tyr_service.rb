# This Ruby script queries the Tyr ("take your route") service
# to associate a latitude-longitude pair with the closest OSM way.
#
# For more information about Tyr, see https://github.com/valhalla/tyr

require 'singleton'

class TyrService
  include Singleton

  BASE_URL = Figaro.env.tyr_host || 'https://valhalla.mapzen.com'
  MAX_LOCATIONS_PER_REQUEST = 100

  class Error < StandardError
  end

  def self.locate(locations: [], costing: 'transit')
    response = connection.get('/locate') do |req|
      json_payload = {
        locations: locations,
        costing: costing
      }
      req.params['json'] = JSON.dump(json_payload)
      req.params['api_token'] = Figaro.env.tyr_auth_token
    end

    if response.body.blank?
      raise Error.new('Tyr returned an empty response')
    elsif [401, 403].include?(response.status)
      raise Error.new('Tyr request was unauthorized. Is TYR_AUTH_TOKEN set?')
    elsif response.status == 504
      raise Error.new('Request to Tyr timed out. Is it running?')
    elsif response.status == 200
      raw_json = response.body
      parsed_json = JSON.parse(raw_json)
      parsed_json.map(&:deep_symbolize_keys)
    else
      raise Error.new("Tyr returns an unexpected error\n#{response.body}")
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
