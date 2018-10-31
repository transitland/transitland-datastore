class Api::V1::RouteStopPatternsController < Api::V1::CurrentEntityController
  def self.model
    RouteStopPattern
  end

  def headways
    set_model
    render :json => rsp_headways([@model]).map { |k,v| [k.join(':'), v] }.to_h
  end

  private

  def rsp_headways(rsps)
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
        key: [:route_stop_pattern_id, :origin_id, :destination_id],
        q: {route_stop_pattern_id: rsps.map(&:id)}, 
        departure_start: between[0], 
        departure_end: between[1], 
        departure_span: departure_span, 
        headway_percentile: headway_percentile
      })
    rescue StandardError => e
      nil
    end
    sids = Stop.select([:id, :onestop_id]).where(id: headways.keys.map { |k| k[1..-1] }.flatten.sort.uniq ).map { |s| [s.id, s.onestop_id] }.to_h
    rids = rsps.map { |i| [i.id, i.onestop_id] }.to_h
    headways.map { |k,v| [[rids[k[0]],sids[k[1]],sids[k[2]]], v]}.to_h
  end


  def index_query
    super
    if params[:traversed_by].present?
      @collection = @collection.where(route: Route.find_by_onestop_id!(params[:traversed_by]))
    end
    if params[:trips].present?
      @collection = @collection.with_trips(AllowFiltering.param_as_array(params, :trips))
    end
    if params[:stops_visited].present?
      @collection = @collection.with_all_stops(params[:stops_visited])
    end
  end

  def index_includes
    super
    @collection = @collection.includes{[
      route,
    ]}
  end

  def query_params
    super.merge({
      traversed_by: {
        desc: "Traversed by RouteStopPattern",
        type: "onestop_id"
      },
      trips: {
        desc: "Imported with GTFS trip ID",
        type: "string",
        array: true
      },
      stops_visited: {
        desc: "Visits Stop",
        type: "onestop_id"
      }
    })
  end
end
