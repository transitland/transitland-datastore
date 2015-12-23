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
    if params[:vehicle_type].present?
      # some count be integers, some could be strings
      vehicle_types_mixed = params[:vehicle_type].split(',')
      # turn them all into integers
      vehicle_types_integers = vehicle_types_mixed.map do |vt|
        if vt.match(/\d+/)
          vt.to_i
        elsif vt.to_s
          GTFS::Route::VEHICLE_TYPES.invert[vt.to_s.titleize.to_sym].to_s.to_i
        end
      end
      @routes = @routes.where(vehicle_type: vehicle_types_integers)
    end
    if params[:bbox].present?
      @routes = @routes.stop_within_bbox(params[:bbox])
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

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @routes,
          Proc.new { |params| api_v1_routes_url(params) },
          params[:offset],
          params[:per_page],
          params[:total],
          params.slice(:identifier, :identifier_starts_with, :operatedBy, :vehicle_type, :bbox, :onestop_id, :tag_key, :tag_value)
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
