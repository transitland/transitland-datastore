class Api::V1::RoutesController < Api::V1::BaseApiController
  include Geojson
  include JsonCollectionPagination
  include DownloadableCsv

  before_action :set_route, only: [:show]

  def index
    @routes = Route.where('')

    if params[:identifier].present?
      @routes = @routes.with_identifier_or_name(params[:identifier])
    elsif params[:identifier_starts_with].present?
      @routes = @routes.with_identifier_starting_with(params[:identifier_starts_with])
    end
    if params[:operatedBy].present?
      @routes = @routes.operated_by(params[:operatedBy])
    end
    if params[:bbox].present?
      @routes = @routes.where_stop_within_bbox(params[:bbox])
    end
    if params[:onestop_id].present?
      @routes = @routes.where(onestop_id: params[:onestop_id])
    end
    if params[:tag_key].present? && params[:tag_value].present?
      @routes = @routes.with_tag_equals(params[:tag_key], params[:tag_value])
    elsif params[:tag_key].present?
      @routes = @routes.with_tag(params[:tag_key])
    end
    if params[:updated_since].present?
      @routes = @routes.updated_since(params[:updated_since])
    end

    @routes = @routes.includes{[
      operator,
      imported_from_feeds,
      imported_from_feed_versions
    ]}

    per_page = params[:per_page].blank? ? Route::PER_PAGE : params[:per_page].to_i

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @routes,
          Proc.new { |params| api_v1_routes_url(params) },
          params[:offset],
          per_page,
          params.slice(:identifier, :identifier_starts_with, :operatedBy, :bbox, :onestop_id, :tag_key, :tag_value)
        )
      end
      format.geojson do
        render json: Geojson.from_entity_collection(@routes)
      end
      format.csv do
        return_downloadable_csv(@routes, 'routes')
      end
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @route }
    end
  end

  private

  def set_route
    @route = Route.find_by_onestop_id!(params[:id])
  end
end
