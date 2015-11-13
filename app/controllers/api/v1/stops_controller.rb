class Api::V1::StopsController < Api::V1::BaseApiController
  include Geojson
  include JsonCollectionPagination
  include DownloadableCsv

  before_action :set_stop, only: [:show]

  def index
    @stops = Stop.where('')

    if params[:identifier].present?
      @stops = @stops.with_identifier_or_name(params[:identifier])
    elsif params[:identifier_starts_with].present?
      @stops = @stops.with_identifier_starting_with(params[:identifier_starts_with])
    end
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
    if params[:onestop_id].present?
      @stops = @stops.where(onestop_id: params[:onestop_id])
    end
    if params[:tag_key].present? && params[:tag_value].present?
      @stops = @stops.with_tag_equals(params[:tag_key], params[:tag_value])
    elsif params[:tag_key].present?
      @stops = @stops.with_tag(params[:tag_key])
    end
    if params[:updated_since].present?
      @stops = @stops.updated_since(params[:updated_since])
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

    per_page = params[:per_page].blank? ? Stop::PER_PAGE : params[:per_page].to_i

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @stops,
          Proc.new { |params| api_v1_stops_url(params) },
          params[:offset],
          per_page,
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

  def show
    render json: @stop
  end

  private

  def set_stop
    @stop = Stop.find_by_onestop_id!(params[:id])
  end
end
