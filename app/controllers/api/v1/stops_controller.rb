class Api::V1::StopsController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include DownloadableCsv
  include AllowFiltering
  include Geojson
  GEOJSON_ENTITY_PROPERTIES = Proc.new { |properties, entity|
    # title property to follow GeoJSON simple style spec
    properties[:title] = entity.name

    properties[:timezone] = entity.timezone
    properties[:operators_serving_stop] = entity.operators.map(&:onestop_id).try(:uniq)
    properties[:routes_serving_stop] = entity.routes.map(&:onestop_id).try(:uniq)
  }

  before_action :set_stop, only: [:show]

  def index
    @stops = Stop.where('')

    @stops = AllowFiltering.by_onestop_id(@stops, params)
    @stops = AllowFiltering.by_tag_keys_and_values(@stops, params)
    @stops = AllowFiltering.by_identifer_and_identifier_starts_with(@stops, params)
    @stops = AllowFiltering.by_updated_since(@stops, params)

    errors = []

    if params[:served_by].present? || params[:servedBy].present?
      # we previously allowed `servedBy`, so we'll continue to honor that for the time being
      operator_onestop_ids = []
      operator_onestop_ids += params[:served_by].split(',') if params[:served_by].present?
      if params[:servedBy].present?
        operator_onestop_ids += params[:servedBy].split(',')
        errors << {
          exception: 'QueryParamDeprecation',
          message: "'servedBy' query paramater is deprecated. Please use 'served_by' in the future."
        }
      end
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
          params.slice(:identifier, :identifier_starts_with, :served_by, :lat, :lon, :r, :bbox, :onestop_id, :tag_key, :tag_value),
          errors
        )
      end
      format.geojson do
        render json: Geojson.from_entity_collection(@stops, &GEOJSON_ENTITY_PROPERTIES)
      end
      format.csv do
        return_downloadable_csv(@stops, 'stops')
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @stop
      end
      format.geojson do
        render json: Geojson.from_entity(@stop, &GEOJSON_ENTITY_PROPERTIES)
      end
    end
  end

  private

  def set_stop
    @stop = Stop.find_by_onestop_id!(params[:id])
  end
end
