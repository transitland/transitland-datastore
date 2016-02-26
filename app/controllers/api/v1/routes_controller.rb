class Api::V1::RoutesController < Api::V1::BaseApiController
  include Geojson
  include JsonCollectionPagination
  include DownloadableCsv
  include AllowFiltering

  before_action :set_route, only: [:show]

  def index
    @routes = Route.where('')

    @routes = AllowFiltering.by_onestop_id(@routes, params)
    @routes = AllowFiltering.by_tag_keys_and_values(@routes, params)
    @routes = AllowFiltering.by_identifer_and_identifier_starts_with(@routes, params)
    @routes = AllowFiltering.by_updated_since(@routes, params)

    if params[:operatedBy].present?
      @routes = @routes.operated_by(params[:operatedBy])
    end
    if params[:traverses].present?
      @routes = @routes.traverses(params[:traverses].split(','))
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

    @routes = @routes.includes{[
      operator,
      route_stop_patterns,
      imported_from_feeds,
      imported_from_feed_versions
    ]}

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @routes,
          Proc.new { |params| api_v1_routes_url(params) },
          params[:sort_key],
          params[:sort_order],
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
