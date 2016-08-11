class Api::V1::StopStationsController < Api::V1::BaseApiController
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
  SERIALIZER = StopStationSerializer

  def index
    @stops = Stop.where(type: nil)

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
    # TODO: served_by_vehicle_types


    @stops = @stops.includes{[
      stop_transfers,
      stop_transfers.to_stop,
      stop_platforms,
      stop_egresses,
      # Self
      imported_from_feeds,
      imported_from_feed_versions,
      operators_serving_stop,
      operators_serving_stop.operator,
      routes_serving_stop,
      routes_serving_stop.route,
      routes_serving_stop.route.operator,
      # stop_platforms
      stop_platforms.imported_from_feeds,
      stop_platforms.imported_from_feed_versions,
      stop_platforms.operators_serving_stop,
      stop_platforms.operators_serving_stop.operator,
      stop_platforms.routes_serving_stop,
      stop_platforms.routes_serving_stop.route,
      stop_platforms.routes_serving_stop.route.operator,
      stop_platforms.stop_transfers,
      stop_platforms.stop_transfers.to_stop,
      # stop_egresses
      stop_egresses.imported_from_feeds,
      stop_egresses.imported_from_feed_versions,
      stop_egresses.operators_serving_stop,
      stop_egresses.operators_serving_stop.operator,
      stop_egresses.routes_serving_stop,
      stop_egresses.routes_serving_stop.route,
      stop_egresses.routes_serving_stop.route.operator,
      stop_egresses.stop_transfers,
      stop_egresses.stop_transfers.to_stop,
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
        if self.class::SERIALIZER
          render json: @stop, serializer: self.class::SERIALIZER
        else
          render json: @stop
        end
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
