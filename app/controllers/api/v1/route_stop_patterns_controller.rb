class Api::V1::RouteStopPatternsController < Api::V1::EntityController
  MODEL = RouteStopPattern

  def index_query
    if params[:traversed_by].present?
      @rsps = @rsps.where(route: Route.find_by_onestop_id!(params[:traversed_by]))
    end
    if params[:trips].present?
      @rsps = @rsps.with_trips(params[:trips])
    end
    if params[:stops_visited].present?
      @rsps = @rsps.with_all_stops(params[:stops_visited])
    end
  end

  def index_includes
    @rsps = @rsps.includes{[
      route,
    ]}
  end

  private

  def query_params
    params.slice(
      :onestop_id,
      :traversed_by,
      :trip,
      :lat,
      :lon,
      :r,
      :bbox,
      :stop_visited,
      :imported_from_feed,
      :imported_from_feed_version,
      :imported_from_active_feed_version,
      :imported_with_gtfs_id,
      :gtfs_id,
      :import_level,
      :trips,
      :embed_issues
    )
  end
end
