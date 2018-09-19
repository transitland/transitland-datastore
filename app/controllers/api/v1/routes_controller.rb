class Api::V1::RoutesController < Api::V1::CurrentEntityController
  def self.model
    Route
  end

  def headways
    set_model
    render :json => route_headways([@model]).map { |k,v| [k.join(':'), v] }.to_h
  end

  private

  def route_headways(routes)
    # headway_* query parameters
    dates = (params[:headway_dates] || "").split(",")
    between = (params[:headway_departure_between] || "").split(",")
    departure_span = params[:headway_departure_span].presence
    h = params[:headway_percentile].presence    
    headway_percentile = h ? h.to_f : 0.5
    headways = {}
    begin
      headways = ScheduleStopPair.headways({
        dates: dates, 
        key: [:route_id, :origin_id, :destination_id],
        q: {route_id: routes.map(&:id)}, 
        departure_start: between[0], 
        departure_end: between[1], 
        departure_span: departure_span, 
        headway_percentile: headway_percentile
      })
    rescue StandardError => e
      nil
    end
    sids = Stop.select([:id, :onestop_id]).where(id: headways.keys.map { |k| k[1..-1] }.flatten.sort.uniq ).map { |s| [s.id, s.onestop_id] }.to_h
    rids = routes.map { |i| [i.id, i.onestop_id] }.to_h
    headways.map { |k,v| [[rids[k[0]],sids[k[1]],sids[k[2]]], v]}.to_h
  end

  def index_query
    super
    if params[:serves].present?
      @collection = @collection.where_serves(AllowFiltering.param_as_array(params, :serves))
    end
    if params[:operated_by].present? || params[:operatedBy].present?
      # we previously allowed `operatedBy`, so we'll continue to honor that for the time being
      param = params[:operated_by].present? ? :operated_by : :operatedBy
      operator_onestop_ids = AllowFiltering.param_as_array(params, param)
      @collection = @collection.operated_by(operator_onestop_ids)
    end
    if params[:traverses].present?
      @collection = @collection.traverses(params[:traverses].split(','))
    end
    if params[:vehicle_type].present?
      # some could be integers, some could be strings
      @collection = @collection.where_vehicle_type(AllowFiltering.param_as_array(params, :vehicle_type))
    end
    if params[:color].present?
      if ['true', true].include?(params[:color])
        @collection = @collection.where.not(color: nil)
      else
        @collection = @collection.where(color: params[:color].upcase)
      end
    end
    if params[:wheelchair_accessible].present?
      @collection = @collection.where(wheelchair_accessible: params[:wheelchair_accessible])
    end
    if params[:bikes_allowed].present?
      @collection = @collection.where(bikes_allowed: params[:bikes_allowed])
    end
  end

  def query_includes
    super
    @collection = @collection.includes{[
      operator,
      stops,
      route_stop_patterns
    ]}
  end

  def index_query_geometry
    if [params[:lat], params[:lon]].map(&:present?).all?
      point = (self.class::MODEL)::GEOFACTORY.point(params[:lon], params[:lat])
      r = params[:r] || 100 # meters TODO: move this to a more logical place
      @collection = @collection.where{st_dwithin(geometry, point, r)}.order{st_distance(geometry, point)}
    end
    if params[:bbox].present?
      @collection = @collection.stop_within_bbox(params[:bbox])
    end
  end

  def paginated_json_collection(collection)
    page = super
    page[:scope] = scope = render_scope
    data = page[:json]
    if scope[:headways]
      scope[:headways_data] = route_headways(data)
    end
    page
  end
  
  def paginated_geojson_collection(collection)
    page = super
    page[:scope] = scope = render_scope
    data = page[:json]
    if scope[:headways]
      scope[:headways_data] = route_headways(data)
    end
    page
  end

  def query_params
    super.merge({
      operated_by: {
        desc: "Operator",
        type: "onestop_id",
        array: true
      },
      operatedBy: {
        show: false
      },
      serves: {
        desc: "Serves Stop",
        type: "onestop_id",
        array: true
      },
      traverses: {
        desc: "Traverses RouteStopPattern",
        type: "onestop_id",
        array: true
      },
      color: {
        desc: "Route color",
        type: "string"
      },
      vehicle_type: {
        desc: "Vehicle type",
        format: "string",
        array: true
      },
      wheelchair_accessible: {
        desc: "Wheelchair accessible",
        format: "boolean",
        array: true
      },
      bikes_allowed: {
        desc: "Bikes allowed",
        format: "boolean"
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
      headway_departure_span: {
        desc: "Minimum daily service span for headway calculation",
        type: "string"
      }
    })
  end
end
