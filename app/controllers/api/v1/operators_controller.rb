class Api::V1::OperatorsController < Api::V1::BaseApiController
  AGGREGATE_CACHE_KEY = 'operators_aggregate_json'

  include JsonCollectionPagination
  include DownloadableCsv
  include AllowFiltering
  include Geojson
  GEOJSON_ENTITY_PROPERTIES = Proc.new { |properties, entity|
    # title property to follow GeoJSON simple style spec
    title = name
    title += " (#{entity.short_name})" if entity.short_name.present?
    properties[:title] = title

    properties[:short_name] = entity.short_name
    properties[:website] = entity.website
    properties[:country] = entity.country
    properties[:state] = entity.state
    properties[:metro] = entity.metro
    properties[:timezone] = entity.timezone
  }

  before_action :set_operator, only: [:show]

  def index
    @operators = Operator.where('')

    @operators = AllowFiltering.by_onestop_id(@operators, params)
    @operators = AllowFiltering.by_tag_keys_and_values(@operators, params)
    @operators = AllowFiltering.by_identifer_and_identifier_starts_with(@operators, params)
    @operators = AllowFiltering.by_updated_since(@operators, params)

    if [params[:lat], params[:lon]].map(&:present?).all?
      point = Operator::GEOFACTORY.point(params[:lon], params[:lat])
      r = params[:r] || 100 # meters TODO: move this to a more logical place
      @operators = @operators.where{st_dwithin(geometry, point, r)}.order{st_distance(geometry, point)}
    end
    if params[:bbox].present?
      @operators = @operators.geometry_within_bbox(params[:bbox])
    end
    if params[:import_level].present?
      @operators = @operators.where_import_level(AllowFiltering.param_as_array(params, :import_level))
    end

    @operators = @operators.includes{[
      imported_from_feeds,
      imported_from_feed_versions,
      feeds
    ]}

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @operators,
          Proc.new { |params| api_v1_operators_url(params) },
          params[:sort_key],
          params[:sort_order],
          params[:offset],
          params[:per_page],
          params[:total],
          params.slice(
            :identifier,
            :identifier_starts_with,
            :lat,
            :lon,
            :r,
            :bbox,
            :onestop_id,
            :tag_key,
            :tag_value,
            :import_level
          )
        )
      end
      format.geojson do
        render json: Geojson.from_entity_collection(@operators, &GEOJSON_ENTITY_PROPERTIES)
      end
      format.csv do
        return_downloadable_csv(@operators, 'operators')
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @operator
      end
      format.geojson do
        render json: Geojson.from_entity(@operator, &GEOJSON_ENTITY_PROPERTIES)
      end
    end
  end

  def aggregate
    # this cache will also be busted whenever an operator is saved
    aggregate_json = Rails.cache.fetch(AGGREGATE_CACHE_KEY, expires_in: 1.day) do
      json = {
        country: {},
        state: {},
        metro: {},
        timezone: {},
        tags: {}
      }
      json[:country] = count_values(Operator.pluck(:country))
      json[:state] = count_values(Operator.pluck(:state))
      json[:metro] = count_values(Operator.pluck(:metro))
      json[:timezone] = count_values(Operator.pluck(:timezone))
      json[:tags] = count_and_gather_values(Operator.pluck(:tags))
      json
    end
    render json: aggregate_json
  end

  private

  def count_values(array_of_hashes)
    return_hash = {}
    counts_hash = array_of_hashes.reduce(Hash.new(0)) do |counts, key|
      counts[key] += 1
      counts
    end
    counts_hash.sort_by { |key, value| -value }.to_h # descending order
    counts_hash.each do |key, value|
      return_hash[key] = {
        count: value
      }
    end
    return_hash
  end

  def count_and_gather_values(array_of_hashes)
    return_hash = {}
    keys = array_of_hashes.map(&:keys).flatten
    values_by_key = group_values_by_key(array_of_hashes)
    counts_by_key = count_values(keys)
    keys.uniq.each do |key|
      return_hash[key] = {
        count: counts_by_key[key][:count],
        values: values_by_key[key]
      }
    end
    return_hash
  end

  def group_values_by_key(array_of_hashes)
    counts_hash = array_of_hashes.reduce(Hash.new {|h,k| h[k]=Set.new}) do |aggregate_hash, incoming_hash|
      incoming_hash.each do |key, value|
        aggregate_hash[key] << value
      end
      aggregate_hash
    end
    counts_hash.sort_by { |key, value| -value.count }.to_h # descending order
  end

  def set_operator
    @operator = Operator.find_by_onestop_id!(params[:id])
  end
end
