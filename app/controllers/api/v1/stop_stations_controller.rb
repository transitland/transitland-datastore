class Api::V1::StopStationsController < Api::V1::CurrentEntityController
  def self.model
    Stop
  end

  private

  def index_query
    super
    @collection = @collection.where(type: nil)
    if params[:served_by].present? || params[:servedBy].present?
      # we previously allowed `servedBy`, so we'll continue to honor that for the time being
      operator_onestop_ids = []
      operator_onestop_ids += params[:served_by].split(',') if params[:served_by].present?
      operator_onestop_ids += params[:servedBy].split(',') if params[:servedBy].present?
      operator_onestop_ids.uniq!
      @collection = @collection.served_by(operator_onestop_ids)
    end
    if params[:served_by_vehicle_types].present?
      @collection = @collection.served_by_vehicle_types(AllowFiltering.param_as_array(params, :served_by_vehicle_types))
    end
    if params[:wheelchair_boarding].present?
      @collection = @collection.where(wheelchair_boarding: AllowFiltering.to_boolean(params[:wheelchair_boarding] ))
    end
    if params[:min_platforms].present?
      @collection = @collection.with_min_platforms(params[:min_platforms].to_i)
    end
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
    super.merge({
      served_by: {
        desc: "Served by Route or Operator",
        type: "onestop_id",
        array: true
      },
      servedBy: {
        show: false
      },
      served_by_vehicle_types: {
        desc: "Served by vehicle types",
        type: "string",
        array: true
      },
      wheelchair_boarding: {
        desc: "Wheelchair boarding",
        type: "boolean"
      },
      min_platforms: {
        desc: "Mininum number of platforms",
        type: "integer"
      }
    })
  end
end
