class Api::V1::StopsController < Api::V1::BaseApiController
  include Geojson
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

    if params[:servedBy].present?
      @stops = @stops.served_by(params[:servedBy].split(','))
    end
    if [params[:lat], params[:lon]].map(&:present?).all?
      point = Stop::GEOFACTORY.point(params[:lon], params[:lat])
      r = params[:r] || 100 # meters TODO: move this to a more logical place
      @stops = @stops.where{st_dwithin(geometry, point, r)}.order{st_distance(geometry, point)}
    end
    if params[:bbox].present?
      @stops = @stops.geometry_within_bbox(params[:bbox])
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
      format.json do
        render paginated_json_collection(
          @stops,
          Proc.new { |params| api_v1_stops_url(params) },
          params[:sort_key],
          params[:sort_order],
          params[:offset],
          params[:per_page],
          params[:total],
          params.slice(:identifier, :identifier_starts_with, :servedBy, :lat, :lon, :r, :bbox, :onestop_id, :tag_key, :tag_value)
        )
      end
      format.geojson do
        render json: Geojson.from_entity_collection(@stops)
      end
      format.csv do
        return_downloadable_csv(@stops, 'stops')
      end
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
    render json: @stop
  end

  private

  def set_stop
    @stop = Stop.find_by_onestop_id!(params[:id])
  end
end
