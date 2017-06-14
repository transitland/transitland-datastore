class Api::V1::RouteStopPatternsController < Api::V1::EntityController
  def self.model
    RouteStopPattern
  end

  private

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
      stop_visited: {
        desc: "Visits Stop",
        type: "onestop_id"
      }
    })
  end
end
