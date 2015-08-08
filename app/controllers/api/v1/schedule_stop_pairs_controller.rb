class Api::V1::ScheduleStopPairsController < Api::V1::BaseApiController
  include Geojson
  include JsonCollectionPagination
  include DownloadableCsv

  def index
    @ssps = ScheduleStopPair.where('')

    # Service on a date
    if params[:date].present?
      @ssps = @ssps.where_service_on_date(params[:date])
    end
    
    # Service between stops
    if params[:origin_onestop_id].present?
      @ssps = @ssps.where(origin_id: Stop.find_by!(onestop_id: params[:origin_onestop_id]).id)
    end
    if params[:destination_onestop_id].present?
      @ssps = @ssps.where(destination_id: Stop.find_by!(onestop_id: params[:destination_onestop_id]).id)
    end
    
    # Service on a route
    if params[:route_onestop_id].present?
      @ssps = @ssps.where(route_id: Route.find_by!(onestop_id: params[:route_onestop_id]).id)
    end

    # Stops in a bounding box
    if params[:bbox].present?
      @ssps = @ssps.where_origin_bbox(params[:bbox])
    end

    per_page = params[:per_page].blank? ? ScheduleStopPair::PER_PAGE : params[:per_page].to_i

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @ssps,
          Proc.new { |params| api_v1_schedule_stop_pairs_url(params) },
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
