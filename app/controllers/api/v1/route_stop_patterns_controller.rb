class Api::V1::RouteStopPatternsController < Api::V1::BaseApiController
  include Geojson
  include JsonCollectionPagination
  include DownloadableCsv

  def index
    @rsps = RouteStopPattern.where('')

    if params[:onestop_id].present?
      @rsps = @rsps.where(onestop_id: params[:onestop_id])
    end

    if params[:bbox].present?
      @rsps = @rsps.geometry_within_bbox(params[:bbox])
    end

    if params[:traversedBy].present?
      @rsps = @rsps.where(route_id: Route.where(onestop_id: params[:traversedBy]))
    end

    if params[:trip].present?
      @rsps = @rsps.where("? = ANY (trips)", params[:trip])
    end

    if params[:stopVisited].present?
      @rsps = @rsps.where("? = ANY (stop_pattern)", params[:stopVisited])
    end

    @rsps = @rsps.includes{[
      route,
      imported_from_feeds,
      imported_from_feed_versions
    ]}

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @rsps,
          Proc.new { |params| api_v1_routes_url(params) },
          params[:offset],
          params[:per_page],
          params[:total],
          params.slice(:onestop_id, :traversedBy)
        )
      end
      format.geojson do
        render json: Geojson.from_entity_collection(@rsps)
      end
      format.csv do
        #return_downloadable_csv(@rsps, 'routes')
      end
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @route }
    end
  end
end
