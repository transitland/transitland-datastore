class Api::V1::StopsController < Api::V1::BaseApiController
  include Geojson
  include JsonCollectionPagination
  include DownloadableCsv

  before_action :set_stop, only: [:show]

  def index
    @stops = Stop.where('')

    if params[:identifier].present?
      @stops = @stops.with_identifier_or_name(params[:identifier])
    end
    if params[:servedBy].present?
      @stops = @stops.served_by(params[:servedBy].split(','))
    end
    if [params[:lat], params[:lon]].map(&:present?).all?
      point = Stop::GEOFACTORY.point(params[:lon], params[:lat])
      r = params[:r] || 100 # meters TODO: move this to a more logical place
      @stops = @stops.where{st_dwithin(geometry, point, r)}.order{st_distance(geometry, point)}
    end
    if params[:bbox].present? && params[:bbox].split(',').length == 4
      bbox_coordinates = params[:bbox].split(',')
      @stops = @stops.where{geometry.op('&&', st_makeenvelope(bbox_coordinates[0], bbox_coordinates[1], bbox_coordinates[2], bbox_coordinates[3], Stop::GEOFACTORY.srid))}
    end

    @stops = @stops.includes{[identifiers, operators_serving_stop, operators_serving_stop.operator]} # TODO: check performance against eager_load, joins, etc.

    per_page = params[:per_page].blank? ? Stop::PER_PAGE : params[:per_page].to_i

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @stops,
          Proc.new { |params| api_v1_stops_url(params) },
          params[:offset],
          per_page
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

  def show
    render json: @stop
  end

  private

  def set_stop
    @stop = Stop.find_by_onestop_id!(params[:id])
  end
end
