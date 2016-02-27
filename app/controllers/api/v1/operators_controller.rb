class Api::V1::OperatorsController < Api::V1::BaseApiController
  include Geojson
  include JsonCollectionPagination
  include DownloadableCsv
  include AllowFiltering

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
          params.slice(:identifier, :identifier_starts_with, :lat, :lon, :r, :bbox, :onestop_id, :tag_key, :tag_value)
        )
      end
      format.geojson do
        render json: Geojson.from_entity_collection(@operators)
      end
      format.csv do
        return_downloadable_csv(@operators, 'operators')
      end
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @operator }
      format.geojson { } # TODO: write this
    end
  end

  private

  def set_operator
    @operator = Operator.find_by_onestop_id!(params[:id])
  end
end
