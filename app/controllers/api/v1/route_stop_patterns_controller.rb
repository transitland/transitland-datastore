class Api::V1::RouteStopPatternsController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include DownloadableCsv
  include AllowFiltering
  include Geojson

  before_action :set_route_stop_pattern, only: [:show]

  def index
    @rsps = RouteStopPattern.where('')

    @rsps = AllowFiltering.by_onestop_id(@rsps, params)
    @rsps = AllowFiltering.by_tag_keys_and_values(@rsps, params)
    @rsps = AllowFiltering.by_identifer_and_identifier_starts_with(@rsps, params)
    @rsps = AllowFiltering.by_updated_since(@rsps, params)

    if params[:imported_from_feed].present?
      @rsps = @rsps.where_imported_from_feed(Feed.find_by_onestop_id(params[:imported_from_feed]))
    end

    if params[:imported_from_feed_version].present?
      @rsps = @rsps.where_imported_from_feed_version(FeedVersion.find_by!(sha1: params[:imported_from_feed_version]))
    end

    if params[:bbox].present?
      @rsps = @rsps.geometry_within_bbox(params[:bbox])
    end

    if params[:traversed_by].present?
      @rsps = @rsps.where(route: Route.find_by_onestop_id!(params[:traversed_by]))
    end

    if params[:trips].present?
      @rsps = @rsps.with_trips(params[:trips])
    end

    if params[:stops_visited].present?
      @rsps = @rsps.with_stops(params[:stops_visited])
    end

    if params[:import_level].present?
      @rsps = @rsps.where_import_level(AllowFiltering.param_as_array(params, :import_level))
    end

    @rsps = @rsps.includes{[
      route,
      imported_from_feeds,
      imported_from_feed_versions
    ]}

    respond_to do |format|
      format.json { render paginated_json_collection(@rsps) }
      format.geojson { render paginated_geojson_collection(@rsps) }
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @route_stop_pattern
      end
      format.geojson do
        render json: Geojson.from_entity(@route_stop_pattern, &GEOJSON_ENTITY_PROPERTIES)
      end
    end
  end

  private

  def query_params
    params.slice(
      :onestop_id,
      :traversed_by,
      :trip,
      :bbox,
      :stop_visited,
      :imported_from_feed,
      :imported_from_feed_version
    )
  end

  def set_route_stop_pattern
    @route_stop_pattern = RouteStopPattern.find_by_onestop_id!(params[:id])
  end
end
