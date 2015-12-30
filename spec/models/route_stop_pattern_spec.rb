# == Schema Information
#
# Table name: current_route_stop_patterns
#
#  id                                 :integer          not null, primary key
#  geometry                           :geography({:srid geometry, 4326
#  tags                               :hstore
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  stop_pattern                       :string           default([]), is an Array
#  version                            :integer
#  created_or_updated_in_changeset_id :integer
#  onestop_id                         :string
#  route_id                           :integer
#  route_type                         :string
#  is_generated                       :boolean          default(FALSE)
#  is_modified                        :boolean          default(FALSE)
#  is_only_stop_points                :boolean          default(FALSE)
#  trips                              :string           default([]), is an Array
#  identifiers                        :string           default([]), is an Array
#
# Indexes
#
#  index_current_route_stop_patterns_on_route_type_and_route_id  (route_type,route_id)
#

describe RouteStopPattern do
  it 'can be created' do
    points = [[-122.401811, 37.706675],[-122.394935, 37.776348]]
    geom = RouteStopPattern::GEOFACTORY.line_string(
      points.map {|lon, lat| RouteStopPattern::GEOFACTORY.point(lon, lat)}
    )
    sp = ["s-9q8yw8y448-bayshorecaltrainstation", "s-9q8yyugptw-sanfranciscocaltrainstation"]
    rsp = create(:route_stop_pattern, stop_pattern: sp, geometry: geom)
    expect(RouteStopPattern.exists?(rsp.id)).to be true
    expect(RouteStopPattern.find(rsp.id).stop_pattern).to match_array(sp)
    expect(RouteStopPattern.find(rsp.id).geometry[:coordinates]).to eq geom.points.map{|p| [p.x,p.y]}
  end

  it 'can create new geometry' do
    expect(RouteStopPattern.line_string([[1,2],[2,2]]).is_a?(RGeo::Geographic::SphericalLineStringImpl)).to be true
  end

  context 'without shape or shape points' do
    before(:each) do
      @trip = GTFS::Trip.new(trip_id: 'test')
      @empty_rsp = RouteStopPattern.new(stop_pattern: [], geometry: RouteStopPattern.line_string([]))
      @geom_rsp = create(:route_stop_pattern,
        stop_pattern: ["s-9q8yw8y448-bayshorecaltrainstation", "s-9q8yyugptw-sanfranciscocaltrainstation"],
        geometry: RouteStopPattern.line_string([[-122.401811, 37.706675],[-122.394935, 37.776348]])
      )
    end

    it 'is marked as empty after evaluation' do
      expect(@empty_rsp.evaluate_geometry(@trip, [])[:empty]).to be true
      expect(@geom_rsp.evaluate_geometry(@trip, [])[:empty]).to be true

      @trip.shape_id = 'test_shape'
      expect(@empty_rsp.evaluate_geometry(@trip, [])[:empty]).to be true
      expect(@geom_rsp.evaluate_geometry(@trip, [])[:empty]).to be false
    end

    it 'adds geometry consisting of stop points' do
      issues = {:empty => true}
      stop_points = [[-122.401811, 37.706675],[-122.394935, 37.776348]]
      @empty_rsp.tl_geometry(stop_points, issues)
      expect(@empty_rsp.geometry[:coordinates]).to eq(stop_points)
    end
  end
end
