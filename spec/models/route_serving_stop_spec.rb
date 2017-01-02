# == Schema Information
#
# Table name: current_routes_serving_stop
#
#  id                                 :integer          not null, primary key
#  route_id                           :integer
#  stop_id                            :integer
#  tags                               :hstore
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#
# Indexes
#
#  c_rss_cu_in_changeset                          (created_or_updated_in_changeset_id)
#  index_current_routes_serving_stop_on_route_id  (route_id)
#  index_current_routes_serving_stop_on_stop_id   (stop_id)
#

describe RouteServingStop do
  it 'can be created' do
    route_serving_stop = create(:route_serving_stop)
    expect(RouteServingStop.exists?(route_serving_stop.id)).to be true
  end

  context 'through changesets' do
    before(:each) do
      @changeset1 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9q8yt4b-19Hollway',
              name: '19th Ave & Holloway St',
              timezone: 'America/Los_Angeles',
              geometry: { type: "Point", coordinates: [-122.475075, 37.721323] }
            }
          },
          {
            action: 'createUpdate',
            operator: {
              onestopId: 'o-9q8y-SFMTA',
              name: 'SFMTA',
              geometry: { type: "Polygon", coordinates:[[[-121.56649700000001,37.00360599999999],[-122.23195700000001,37.48541199999998],[-122.38653400000001,37.600005999999965],[-122.412018,37.63110599999998],[-122.39432299999996,37.77643899999997],[-121.65072100000002,37.12908099999998],[-121.61080899999999,37.085774999999984],[-121.56649700000001,37.00360599999999]]]}
            },
          },
          {
            action: 'createUpdate',
            route: {
              onestopId: 'r-9q8y-19Express',
              name: 'Fictional 19th Ave. Express',
              operatedBy: 'o-9q8y-SFMTA',
              serves: ['s-9q8yt4b-19Hollway'],
              geometry: {
                type: 'MultiLineString',
                coordinates: [
                  [[-73.87481689453125, 40.88860081193033],[ -73.9764404296875, 40.763901280945866],[ -73.94622802734375, 40.686886382151116],[ -73.9544677734375, 40.61186744303007]],
                  [[-74.1851806640625,40.81588791441588],[-74.00665283203124,40.83251504043271],[-73.948974609375,40.7909394098518],[-73.8006591796875,40.751418432997426],[-73.4326171875,40.79301881008675]]
                ]
              }
            }
          }
        ]
      })
    end

    it 'can be created and edited' do
      @changeset1.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-19Hollway').operators).to include Operator.find_by_onestop_id!('o-9q8y-SFMTA')
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-19Hollway').routes).to include Route.find_by_onestop_id!('r-9q8y-19Express')
      expect(@changeset1.stops_created_or_updated).to match_array([Stop.find_by_onestop_id!('s-9q8yt4b-19Hollway')])
      expect(@changeset1.operators_created_or_updated).to match_array([Operator.find_by_onestop_id!('o-9q8y-SFMTA')])
      expect(@changeset1.routes_created_or_updated).to match_array([Route.find_by_onestop_id!('r-9q8y-19Express')])
      expect(@changeset1.operators_serving_stop_created_or_updated).to match_array([
        OperatorServingStop.find_by_attributes({ operator_onestop_id: 'o-9q8y-SFMTA', stop_onestop_id: 's-9q8yt4b-19Hollway'})
      ])
      expect(@changeset1.routes_serving_stop_created_or_updated).to match_array([
        RouteServingStop.find_by_attributes({ route_onestop_id: 'r-9q8y-19Express', stop_onestop_id: 's-9q8yt4b-19Hollway'})
      ])
      expect(Route.find_by_onestop_id!('r-9q8y-19Express').geometry[:coordinates][0][0]).to eq [-73.87481689453125, 40.88860081193033]
    end

    it 'can be destroyed' do
      @changeset1.apply!
      changeset2 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            route: {
              onestopId: 'r-9q8y-19Express',
              doesNotServe: ['s-9q8yt4b-19Hollway']
            }
          }
        ]
      })
      changeset2.apply!
      expect(RouteServingStop.count).to eq 0
      expect(OldRouteServingStop.count).to eq 1
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-19Hollway').routes.count).to eq 0
    end

    it 'will be removed when stop is destroyed' do
      @changeset1.apply!
      changeset2 = create(:changeset, payload: {
        changes: [
          {
            action: 'destroy',
            stop: {
              onestopId: 's-9q8yt4b-19Hollway'
            }
          }
        ]
      })
      changeset2.apply!
      expect(RouteServingStop.count).to eq 0
      expect(OperatorServingStop.count).to eq 0
      expect(OldRouteServingStop.count).to eq 1
      expect(OldOperatorServingStop.count).to eq 1
      expect(Route.find_by_onestop_id!('r-9q8y-19Express').stops.count).to eq 0
      expect(OldRouteServingStop.first.stop).to be_a OldStop
      expect(OldStop.first.old_routes_serving_stop.first.route).to eq Route.find_by_onestop_id!('r-9q8y-19Express')
      expect(OldStop.first.old_operators_serving_stop.first.operator).to eq Operator.find_by_onestop_id!('o-9q8y-SFMTA')
    end

    it 'will be removed when route is destroyed' do
      @changeset1.apply!
      changeset2 = create(:changeset, payload: {
        changes: [
          {
            action: 'destroy',
            route: {
              onestopId: 'r-9q8y-19Express'
            }
          }
        ]
      })
      changeset2.apply!
      expect(RouteServingStop.count).to eq 0
      expect(OldRouteServingStop.count).to eq 1
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-19Hollway').routes.count).to eq 0
      expect(OldRouteServingStop.first.route).to be_a OldRoute
      expect(OldRouteServingStop.first.stop).to eq Stop.find_by_onestop_id!('s-9q8yt4b-19Hollway')
    end
  end
end
