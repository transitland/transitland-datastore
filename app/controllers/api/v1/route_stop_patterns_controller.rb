class Api::V1::RouteStopPatternsController < Api::V1::BaseApiController
  include Geojson
  include JsonCollectionPagination
  include DownloadableCsv

  def index
    @rsps = RouteStopPattern.where('')

    if params[:onestop_id].present?
      # TODO: hash symbol issue!
      @rsps = @rsps.where(onestop_id: params[:onestop_id])
    end

    if params[:traversedBy].present?
      @rsps = @rsps.route_onestop_id(params[:traversedBy])
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
          params.slice(:onestop_id)
        )
      end
      format.geojson do
        render json: Geojson.from_entity_collection(@rsps)
      end
      format.csv do
        return_downloadable_csv(@rsps, 'routes')
      end
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @route }
    end
  end
end
