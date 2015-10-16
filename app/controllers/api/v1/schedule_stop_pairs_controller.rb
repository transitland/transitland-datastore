class Api::V1::ScheduleStopPairsController < Api::V1::BaseApiController
  include Geojson
  include JsonCollectionPagination
  include DownloadableCsv

  before_action :set_schedule_stop_pairs

  def index
    per_page = params[:per_page].blank? ? ScheduleStopPair::PER_PAGE : params[:per_page].to_i
    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @ssps,
          Proc.new { |params| api_v1_schedule_stop_pairs_url(params) },
          params[:offset],
          per_page,
          params.slice(:date, :service_from_date, :origin_onestop_id, :destination_onestop_id, :route_onestop_id, :bbox, :updated_since)
        )
      end
      format.geojson do
        render json: Geojson.from_entity_collection(@ssps)
      end
    end
  end

  def summarize
    edges = {}
    ssps.find_each do |ssp|

    end
  end

  def set_schedule_stop_pairs
    @ssps = ScheduleStopPair.where('')
    # Service on a date
    if params[:date].present?
      @ssps = @ssps.where_service_on_date(params[:date])
    end
    if params[:service_from_date].present?
      @ssps = @ssps.where_service_from_date(params[:service_from_date])
    end
    # Service between stops
    if params[:origin_onestop_id].present?
      @ssps = @ssps.where(origin_id: Stop.find_by!(onestop_id: params[:origin_onestop_id]).id)
    end
    if params[:destination_onestop_id].present?
      @ssps = @ssps.where(destination_id: Stop.find_by!(onestop_id: params[:destination_onestop_id]).id)
    end
    # Departing between...
    if params[:departing_between].present?
      t1, t2 = params[:departing_between].split(',')
      @ssps = @ssps.where_departing_between(t1, t2)
    end
    # Service by trip id
    if params[:trip].present?
      @ssps = @ssps.where(trip: params[:trip])
    end
    # Service on a route
    if params[:route_onestop_id].present?
      @ssps = @ssps.where(route_id: Route.find_by!(onestop_id: params[:route_onestop_id]).id)
    end
    if params[:operator_onestop_id].present?
      @ssps = @ssps.where(operator: Operator.find_by!(onestop_id: params[:operator_onestop_id]))
    end
    # Stops in a bounding box
    if params[:bbox].present?
      @ssps = @ssps.where_origin_bbox(params[:bbox])
    end
    # Edges updated since
    if params[:updated_since].present?
      @ssps = @ssps.updated_since(params[:updated_since])
    end
    # Eager load
    @ssps = @ssps.includes(:operator, :route, :origin, :destination)
  end

end
