class Api::V1::StopStationsController < Api::V1::EntityController
  def self.model
    Stop
  end

  private

  def index_query
    super
    @collection = @collection.where(type: nil)
  end

  def index_includes
    super
    @collection = @collection.includes{[
      stop_transfers,
      stop_transfers.to_stop,
      stop_platforms,
      stop_egresses,
      # Self
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
      stop_egresses.stop_transfers.to_stop
    ]} # TODO: check performance against eager_load, joins, etc.

    if AllowFiltering.to_boolean(params[:embed_issues])
      @collection = @collection.includes{[stop_platforms.issues, stop_egresses.issues]}
    end
  end

  def paginated_json_collection(collection)
    result = super
    result[:root] = :stop_stations
    result
  end

  def render_serializer
    StopStationSerializer
  end

  def query_params
    params.slice(
      :served_by,
      :servedBy,
      :served_by_vehicle_types,
      :wheelchair_boarding,
      :lat,
      :lon,
      :r,
      :bbox,
      :onestop_id,
      :tag_key,
      :tag_value,
      :import_level,
      :imported_with_gtfs_id,
      :gtfs_id,
      :imported_from_feed,
      :imported_from_feed_version,
      :imported_from_active_feed_version
    )
  end
end
