class Api::V1::RoutesController < Api::V1::BaseApiController
  include JsonCollectionPagination

  before_action :set_route, only: [:show]

  def index
    @routes = Route.includes(:identifiers).where('') # TODO: check performance against eager_load, joins, etc.

    if params[:identifier].present?
      @routes = @routes.with_identifier(params[:identifier])
    end
    if params[:bbox].present? && params[:bbox].split(',').length == 4
      bbox_coordinates = params[:bbox].split(',')
      @routes = @routes.where{geometry.op('&&', st_makeenvelope(bbox_coordinates[0], bbox_coordinates[1], bbox_coordinates[2], bbox_coordinates[3], Route::GEOFACTORY.srid))}
    end

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @routes,
          Proc.new { |params| api_v1_routes_url(params) },
          params[:offset],
          Route::PER_PAGE
        )
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
