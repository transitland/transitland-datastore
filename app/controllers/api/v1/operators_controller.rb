class Api::V1::OperatorsController < Api::V1::BaseApiController
  AGGREGATE_CACHE_KEY = 'operators_aggregate_json'

  include JsonCollectionPagination
  include DownloadableCsv
  include AllowFiltering

  before_action :set_operator, only: [:show]

  def index
    # Entity
    @operators = Operator.where('')
    @operators = AllowFiltering.by_onestop_id(@operators, params)
    @operators = AllowFiltering.by_tag_keys_and_values(@operators, params)
    @operators = AllowFiltering.by_identifer_and_identifier_starts_with(@operators, params)
    @operators = AllowFiltering.by_updated_since(@operators, params)

    # Imported From Feed
    if params[:imported_from_feed].present?
      @operators = @operators.where_imported_from_feed(Feed.find_by_onestop_id(params[:imported_from_feed]))
    end
    if params[:imported_from_feed_version].present?
      @operators = @operators.where_imported_from_feed_version(FeedVersion.find_by!(sha1: params[:imported_from_feed_version]))
    end
    if params[:imported_from_active_feed_version].presence.eql?("true")
      @operators = @operators.where_imported_from_active_feed_version
    end
    if params[:imported_with_gtfs_id].present?
      @operators = @operators.where_imported_with_gtfs_id(params[:gtfs_id])
    end
    if params[:import_level].present?
      @operators = @operators.where_import_level(AllowFiltering.param_as_array(params, :import_level))
    end

    # Geometry
    if [params[:lat], params[:lon]].map(&:present?).all?
      point = Operator::GEOFACTORY.point(params[:lon], params[:lat])
      r = params[:r] || 100 # meters TODO: move this to a more logical place
      @operators = @operators.where{st_dwithin(geometry, point, r)}.order{st_distance(geometry, point)}
    end
    if params[:bbox].present?
      @operators = @operators.geometry_within_bbox(params[:bbox])
    end

    # Operators
    @operators = AllowFiltering.by_attribute_array(@operators, params, :country)
    @operators = AllowFiltering.by_attribute_array(@operators, params, :state)
    @operators = AllowFiltering.by_attribute_array(@operators, params, :metro)
    @operators = AllowFiltering.by_attribute_array(@operators, params, :timezone)
    @operators = AllowFiltering.by_attribute_array(@operators, params, :name, case_sensitive: true)
    @operators = AllowFiltering.by_attribute_array(@operators, params, :short_name)

    # Includes
    @operators = @operators.includes{[
      imported_from_feeds,
      imported_from_feed_versions,
      feeds
    ]}
    @operators = @operators.includes(:issues) if AllowFiltering.to_boolean(params[:embed_issues])

    respond_to do |format|
      format.json { render paginated_json_collection(@operators).merge({ scope: { embed_issues: AllowFiltering.to_boolean(params[:embed_issues]) } }) }
      format.geojson { render paginated_geojson_collection(@operators) }
      format.csv { return_downloadable_csv(@operators, 'operators') }
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @operator, scope: { embed_issues: AllowFiltering.to_boolean(params[:embed_issues]) }  }
      format.geojson { render json: @operator, serializer: GeoJSONSerializer }
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
        name: {},
        short_name: {},
        tags: {}
      }
      json[:country] = count_values(Operator.pluck(:country), attr_name: :country)
      json[:state] = count_values(Operator.pluck(:state), attr_name: :state)
      json[:metro] = count_values(Operator.pluck(:metro), attr_name: :metro)
      json[:timezone] = count_values(Operator.pluck(:timezone), attr_name: :timezone)
      json[:name] = count_values(Operator.pluck(:name), attr_name: :name)
      json[:short_name] = count_values(Operator.pluck(:short_name), attr_name: :short_name)
      json[:tags] = count_and_gather_values(Operator.pluck(:tags))
      json
    end
    render json: aggregate_json
  end

  private

  def query_params
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
      :import_level,
      :name,
      :short_name,
      :imported_from_feed,
      :imported_from_feed_version
    )
  end

  def count_values(array_of_hashes, attr_name: nil)
    return_hash = {}
    counts_hash = array_of_hashes.reduce(Hash.new(0)) do |counts, key|
      counts[key] += 1
      counts
    end
    counts_hash.sort_by { |key, value| -value }.to_h # descending order
    counts_hash.each do |key, value|
      return_hash[key] ||= {}
      return_hash[key][:count] = value
      if attr_name.present?
        return_hash[key][:query_url] = api_v1_operators_url("#{attr_name}".to_sym => key)
      end
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
        values: values_by_key[key],
        query_url: api_v1_operators_url(tag_key: key)
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
