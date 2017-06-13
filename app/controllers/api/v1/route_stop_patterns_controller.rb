class Api::V1::RouteStopPatternsController < Api::V1::EntityController
  def self.model
    RouteStopPattern
  end

  private

  def index_query
    super
    if params[:traversed_by].present?
      @collection = @collection.where(route: Route.find_by_onestop_id!(params[:traversed_by]))
    end
    if params[:trips].present?
      @collection = @collection.with_trips(AllowFiltering.param_as_array(params, :trips))
    end
    if params[:stops_visited].present?
      @collection = @collection.with_all_stops(params[:stops_visited])
    end
  end

  def index_includes
    super
    @collection = @collection.includes{[
      route,
    ]}
  end

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
