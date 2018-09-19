class Api::V1::StopsController < Api::V1::CurrentEntityController
  def self.model
    Stop
  end

  def headways
    set_model
    render :json => stop_headways([@model]).map { |k,v| [k.join(':'), v] }.to_h
  end

  private

  def stop_headways(stops)
    # headway_* query parameters
    dates = (params[:headway_dates] || "").split(",")
    between = (params[:headway_departure_between] || "").split(",")
    departure_span = params[:headway_span].presence
    h = params[:headway_percentile].presence    
    headway_percentile = h ? h.to_f : 0.5
    headways = {}
    begin
      headways = ScheduleStopPair.headways({
        dates: dates, 
        key: [:origin_id, :destination_id],
        q: {origin_id: stops.map(&:id)}, 
        departure_start: between[0], 
        departure_end: between[1], 
        departure_span: departure_span, 
        headway_percentile: headway_percentile
      })
    rescue StandardError => e
      puts "stop_headways error: #{e}"
      nil
    end
    sids = Stop.select([:id, :onestop_id]).where(id: headways.keys.flatten.sort.uniq ).map { |s| [s.id, s.onestop_id] }.to_h
    headways.map { |k,v| [[sids[k[0]], sids[k[1]]], v]}.to_h
  end

  def index_query
    super
    if params[:served_by].present? || params[:servedBy].present?
      # we previously allowed `servedBy`, so we'll continue to honor that for the time being
      operator_onestop_ids = []
      operator_onestop_ids += params[:served_by].split(',') if params[:served_by].present?
      operator_onestop_ids += params[:servedBy].split(',') if params[:servedBy].present?
      operator_onestop_ids.uniq!
      @collection = @collection.served_by(operator_onestop_ids)
    end
    if params[:served_by_vehicle_types].present?
      @collection = @collection.served_by_vehicle_types(AllowFiltering.param_as_array(params, :served_by_vehicle_types))
    end
    if params[:wheelchair_boarding].present?
      @collection = @collection.where(wheelchair_boarding: AllowFiltering.to_boolean(params[:wheelchair_boarding] ))
    end
  end

  def index_includes
    super
    @collection = @collection.includes{[
      operators_serving_stop,
      operators_serving_stop.operator,
      routes_serving_stop,
      routes_serving_stop.route,
      routes_serving_stop.route.operator
    ]}
  end

  def paginated_json_collection(collection)
    page = super
    page[:root] = :stops
    page[:each_serializer] = StopSerializer    
    page[:scope] = scope = render_scope
    data = page[:json]
    if scope[:headways]
      scope[:headways_data] = stop_headways(data)
    end
    page
  end
  
  def paginated_geojson_collection(collection)
    page = super
    page[:scope] = scope = render_scope
    data = page[:json]
    if scope[:headways]
      scope[:headways_data] = stop_headways(data)
    end
    page
  end

  def query_params
    super.merge({
      served_by: {
        desc: "Served by Route or Operator",
        type: "onestop_id",
        array: true
      },
      servedBy: {
        show: false
      },
      served_by_vehicle_types: {
        desc: "Served by vehicle types",
        type: "string",
        array: true
      },
      wheelchair_boarding: {
        desc: "Wheelchair boarding",
        type: "boolean"
      },
      headway_dates: {
        desc: "Dates for headway calculation",
        type: "string",
        array: true
      },
      headway_departure_between: {
        desc: "Origin departure times for headway calculation",
        type: "string",
        array: true
      },
      headway_percentile: {
        desc: "Percentile to use for headway calculation",
        type: "float"
      },
      headway_span: {
        desc: "Minimum daily service span for headway calculation",
        type: "string"
      }  
    })
  end
end
