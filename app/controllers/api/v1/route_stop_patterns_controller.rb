class Api::V1::RouteStopPatternsController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include DownloadableCsv
  include AllowFiltering

  before_action :set_route_stop_pattern, only: [:show]

  def index
    # Entity
    @rsps = RouteStopPattern.where('')
    @rsps = AllowFiltering.by_onestop_id(@rsps, params)
    @rsps = AllowFiltering.by_tag_keys_and_values(@rsps, params)
    @rsps = AllowFiltering.by_updated_since(@rsps, params)

    # Imported From Feed
    if params[:imported_from_feed].present?
      @rsps = @rsps.where_imported_from_feed(Feed.find_by_onestop_id(params[:imported_from_feed]))
    end
    if params[:imported_from_feed_version].present?
      @rsps = @rsps.where_imported_from_feed_version(FeedVersion.find_by!(sha1: params[:imported_from_feed_version]))
    end
    if params[:imported_from_active_feed_version].presence.eql?("true")
      @rsps = @rsps.where_imported_from_active_feed_version
    end
    if params[:imported_with_gtfs_id].present?
      @rsps = @rsps.where_imported_with_gtfs_id(params[:imported_with_gtfs_id])
    end
    if params[:import_level].present?
      @rsps = @rsps.where_import_level(AllowFiltering.param_as_array(params, :import_level))
    end

    # Geometry
    if [params[:lat], params[:lon]].map(&:present?).all?
      point = RouteStopPattern::GEOFACTORY.point(params[:lon], params[:lat])
      r = params[:r] || 100 # meters TODO: move this to a more logical place
      @rsps = @rsps.where{st_dwithin(geometry, point, r)}.order{st_distance(geometry, point)}
    end
    if params[:bbox].present?
      @rsps = @rsps.geometry_within_bbox(params[:bbox])
    end

    # RouteStopPatterns
    if params[:traversed_by].present?
      @rsps = @rsps.where(route: Route.find_by_onestop_id!(params[:traversed_by]))
    end
    if params[:trips].present?
      @rsps = @rsps.with_trips(params[:trips])
    end
    if params[:stops_visited].present?
      @rsps = @rsps.with_all_stops(params[:stops_visited])
    end

    # Includes
    @rsps = @rsps.includes{[
      route,
      imported_from_feeds,
      imported_from_feed_versions
    ]}
    @rsps = @rsps.includes(:issues) if AllowFiltering.to_boolean(params[:embed_issues])

    respond_to do |format|
      format.json { render paginated_json_collection(@rsps).merge({ scope: { embed_issues: AllowFiltering.to_boolean(params[:embed_issues]) } }) }
      format.geojson { render paginated_geojson_collection(@rsps) }
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @route_stop_pattern, scope: { embed_issues: AllowFiltering.to_boolean(params[:embed_issues]) } }
      format.geojson { render json: @route_stop_pattern, serializer: GeoJSONSerializer }
    end
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
      :import_level,
      :trips,
      :embed_issues
    )
  end

  def set_route_stop_pattern
    @route_stop_pattern = RouteStopPattern.find_by_onestop_id!(params[:id])
  end
end
