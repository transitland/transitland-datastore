# This service updates the changeset's entity attributes that are computed/derived from the attribute data
# of multiple entity types. For example, here RouteStopPatterns will have to have their stop distances recomputed
# using both the RouteStopPattern and its stop_pattern Stops' geometries. Operators have their convex hulls
# recomputed from the Stops it serves.
#
# Ideally we would like to define methods at the model level (that would be the first place to put new
# recomputed attribute functionality if possible) but the need to avoid duplicate recomputation on entities of update
# changesets complicates this. E.g, We don't want to recompute the stop_distances of one RouteStopPattern
# multiple times if there are multiple Stops of that RouteStopPattern in the changeset.

class UpdateComputedAttributes
  attr_accessor :changeset

  def initialize(changeset: nil)
    @changeset = changeset
  end

  def update_computed_attributes
    raise NotImplementedError
  end
end

class UpdateComputedAttributes::GeometryUpdateComputedAttributes < UpdateComputedAttributes
  attr_accessor :rsps_to_update_distances
  attr_accessor :operators_to_update_convex_hull
  attr_accessor :old_issues_to_deprecate

  def update_computed_attributes
    @rsps_to_update_distances = Set.new
    @old_issues_to_deprecate = Set.new
    @operators_to_update_convex_hull = Set.new

    unless @changeset.stops_created_or_updated.empty?
      @changeset.stops_created_or_updated.each do |stop|
        @operators_to_update_convex_hull.merge(OperatorServingStop.where(stop: stop).map(&:operator))
      end
      @rsps_to_update_distances.merge(RouteStopPattern.with_any_stops(@changeset.stops_created_or_updated.map(&:onestop_id)))
    end

    update_operators_convex_hull

    compute_routes_representative_geometries

    update_rsps_and_ssps_stop_distances

    #second array item mainly for testing
    [@old_issues_to_deprecate, [@rsps_to_update_distances.size, @operators_to_update_convex_hull.size]]
  end

  private

  def update_operators_convex_hull
    @operators_to_update_convex_hull.each { |operator|
      operator.geometry = operator.recompute_convex_hull_around_stops

      @old_issues_to_deprecate.merge(Issue.issues_of_entity(operator, entity_attributes: ["geometry"]))
      operator.update_making_history(changeset: @changeset)
    }
  end

  def compute_routes_representative_geometries
    # Recompute and update the Route model representative geometry
    route_rsps = {}
    @changeset.route_stop_patterns_created_or_updated.each do |rsp|
      route_rsps[rsp.route] ||= Set.new
      route_rsps[rsp.route] << rsp
    end
    route_rsps.each_pair do |route, rsps|
      representative_rsps = Route.representative_geometry(route, rsps || [])
      Route.geometry_from_rsps(route, representative_rsps)
      route.update_making_history(changeset: @changeset)
    end
  end

  def update_rsps_and_ssps_stop_distances
    # Recompute and update RouteStopPattern distances and associated ScheduleStopPairs
    @rsps_to_update_distances.merge(@changeset.route_stop_patterns_created_or_updated)
    log "Calculating distances" unless @rsps_to_update_distances.empty?
    @rsps_to_update_distances.each { |rsp|
      @old_issues_to_deprecate.merge(Issue.issues_of_entity(rsp, entity_attributes: ["stop_distances"]))

      begin
        stop_distances = Geometry::TLDistances.new(rsp).calculate_distances
        rsp.update_making_history(changeset: @changeset, new_attrs: { stop_distances: stop_distances })
      rescue StandardError
        log "Could not calculate distances for Route Stop Pattern: #{rsp.onestop_id}"
        rsp.update_making_history(changeset: @changeset, new_attrs: { stop_distances: Geometry::DistanceCalculation.new(rsp[:geometry], rsp.stops).fallback_distances })
      end

      rsp.ordered_ssp_trip_chunks { |trip_chunk|
        trip_chunk.each_with_index do |ssp, i|
          ssp.update_column(:origin_dist_traveled, rsp.stop_distances[i])
          ssp.update_column(:destination_dist_traveled, rsp.stop_distances[i+1])
        end
      }
    }
  end
end

class PostQualityCheckUpdate

end
