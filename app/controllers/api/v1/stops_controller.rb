class Api::V1::StopsController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include DownloadableCsv
  include AllowFiltering

  before_action :set_stop, only: [:show]

  # GET /stops
  include Swagger::Blocks
  swagger_path '/stops' do
    operation :get do
      key :tags, ['stop']
      key :name, :tags
      key :summary, 'Returns all stops with filtering and sorting'
      key :produces, [
        'application/json',
        'application/vnd.geo+json',
        'text/csv'
      ]
      parameter do
        key :name, :onestop_id
        key :in, :query
        key :description, 'Onestop ID(s) to filter by'
        key :required, false
        key :type, :string
      end
      parameter do
        key :name, :servedBy
        key :in, :query
        key :description, 'operator Onestop ID(s) to filter by'
        key :required, false
        key :type, :string
      end
      # parameter do
      #   key :name, :identifier
      #   key :in, :query
      #   key :description, 'identifier to filter by'
      #   key :required, false
      #   key :type, :string
      # end
      # parameter do
        # key :'$ref', '#/parameters/jsonCollectionPagination/perPageParam'
      # end
      response 200 do
        # key :description, 'stop response'
        schema do
          key :type, :array
          items do
            key :'$ref', :Stop
          end
        end
      end
    end
  end
  def index
    @stops = Stop.where('')

    @stops = AllowFiltering.by_onestop_id(@stops, params)
    @stops = AllowFiltering.by_tag_keys_and_values(@stops, params)
    @stops = AllowFiltering.by_identifer_and_identifier_starts_with(@stops, params)
    @stops = AllowFiltering.by_updated_since(@stops, params)

    if params[:imported_from_feed].present?
      @stops = @stops.where_imported_from_feed(Feed.find_by_onestop_id(params[:imported_from_feed]))
    end

    if params[:imported_from_feed_version].present?
      @stops = @stops.where_imported_from_feed_version(FeedVersion.find_by!(sha1: params[:imported_from_feed_version]))
    end

    if params[:served_by].present? || params[:servedBy].present?
      # we previously allowed `servedBy`, so we'll continue to honor that for the time being
      operator_onestop_ids = []
      operator_onestop_ids += params[:served_by].split(',') if params[:served_by].present?
      operator_onestop_ids += params[:servedBy].split(',') if params[:servedBy].present?
      operator_onestop_ids.uniq!
      @stops = @stops.served_by(operator_onestop_ids)
    end
    if [params[:lat], params[:lon]].map(&:present?).all?
      point = Stop::GEOFACTORY.point(params[:lon], params[:lat])
      r = params[:r] || 100 # meters TODO: move this to a more logical place
      @stops = @stops.where{st_dwithin(geometry, point, r)}.order{st_distance(geometry, point)}
    end
    if params[:bbox].present?
      @stops = @stops.geometry_within_bbox(params[:bbox])
    end
    if params[:import_level].present?
      @stops = @stops.where_import_level(AllowFiltering.param_as_array(params, :import_level))
    end
    if params[:served_by_vehicle_types].present?
      @stops = @stops.served_by_vehicle_types(AllowFiltering.param_as_array(params, :served_by_vehicle_types))
    end
    if params[:wheelchair_boarding].present?
      @stops = @stops.where(wheelchair_boarding: AllowFiltering.to_boolean(params[:wheelchair_boarding] ))
    end

    @stops = @stops.includes{[
      operators_serving_stop,
      operators_serving_stop.operator,
      routes_serving_stop,
      routes_serving_stop.route,
      routes_serving_stop.route.operator,
      imported_from_feeds,
      imported_from_feed_versions
    ]} # TODO: check performance against eager_load, joins, etc.

    respond_to do |format|
      format.json { render paginated_json_collection(@stops) }
      format.geojson { render paginated_geojson_collection(@stops) }
      format.csv { return_downloadable_csv(@stops, 'stops') }
    end
  end

  # GET /stops/{onestop_id}
  include Swagger::Blocks
  swagger_path '/stops/{onestop_id}' do
    operation :get do
      key :tags, ['stop']
      key :name, :tags
      key :summary, 'Returns one stop by its Onestop ID'
      key :produces, [
        'application/json',
        # 'application/vnd.geo+json',
      ]
      parameter do
        key :name, :onestop_id
        key :in, :path
        key :description, 'Onestop ID to filter by'
        key :required, true
        key :type, :string
      end
      response 200 do
        # key :description, 'stop response'
        schema do
          key :'$ref', :Stop
        end
      end
    end
  end
  def show
    respond_to do |format|
      format.json { render json: @stop, serializer: StopSerializer }
      format.geojson { render json: @stop, serializer: GeoJSONSerializer }
    end
  end

  def paginated_json_collection(collection)
    result = super
    result[:root] = :stops
    result[:each_serializer] = StopSerializer
    result
  end

  private

  def query_params
    params.slice(
      :identifier,
      :identifier_starts_with,
      :served_by,
      :servedBy,
      :lat,
      :lon,
      :r,
      :bbox,
      :onestop_id,
      :tag_key,
      :tag_value,
      :import_level,
      :imported_from_feed,
      :imported_from_feed_version
    )
  end

  def set_stop
    @stop = Stop.find_by_onestop_id!(params[:id])
  end
end
