class Api::V1::SchedulesController < Api::V1::BaseApiController
  include Geojson
  include JsonCollectionPagination
  include DownloadableCsv

  def index
    @ssps = ScheduleStopPair.where('')

    # Service on a date
    if params[:date].present?
      date = Date.parse(params[:date])
      d = date.strftime('%Y%m%d')
      dw = date.strftime("%A").downcase
      @ssps = @ssps.where("(service_start_date < ? AND service_end_date > ?) AND (service_#{dw} = true OR ? = ANY(service_added)) AND NOT (? = ANY(service_except))", d, d, d, d)
    end
    
    # Service between stops
    if params[:origin_onestop_id].present?
      @ssps = @ssps.where(origin_id: Stop.find_by(onestop_id: params[:origin_onestop_id]).id)
    end
    if params[:destination_onestop_id].present?
      @ssps = @ssps.where(destination_id: Stop.find_by(onestop_id: params[:destination_onestop_id]).id)
    end
    
    # Service on a route
    if params[:route_onestop_id].present?
      @ssps = @ssps.where(route_id: Route.find_by(onestop_id: params[:route_onestop_id]).id)
    end

    # Stops in a bounding box
    if params[:bbox].present? && params[:bbox].split(',').length == 4
      bbox_coordinates = params[:bbox].split(',')
      stops = Stop.where{geometry.op('&&', st_makeenvelope(bbox_coordinates[0], bbox_coordinates[1], bbox_coordinates[2], bbox_coordinates[3], Stop::GEOFACTORY.srid))}
      @ssps = @ssps.where(origin_id: stops.ids)      
    end

    per_page = params[:per_page].blank? ? ScheduleStopPair::PER_PAGE : params[:per_page].to_i

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @ssps,
          Proc.new { |params| api_v1_schedules_url(params) },
          params[:offset],
          per_page,
          params.slice(:service_start_date, :service_end_date)
        )
      end
      format.geojson do
        render json: Geojson.from_entity_collection(@ssps)
      end
      # format.csv do
      #   return_downloadable_csv(@ssps, 'ssps')
      # end
    end

  end

  def frequency
    
  end

end
