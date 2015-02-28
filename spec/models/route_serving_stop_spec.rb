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
    expect(RouteServingStop.exists?(route_serving_stop)).to be true
  end

  context 'through changesets' do
    before(:each) do
      @changeset1 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9q8yt4b-19Hollway',
              name: '19th Ave & Holloway St'
            }
          },
          {
            action: 'createUpdate',
            operator: {
              onestopId: 'o-9q8y-SFMTA',
              name: 'SFMTA'
            },
          },
          {
            action: 'createUpdate',
            route: {
              onestopId: 'r-9q8y-19Express',
              name: 'Fictional 19th Ave. Express',
              operatedBy: 'o-9q8y-SFMTA',
              serves: ['s-9q8yt4b-19Hollway']
            }
          }
        ]
      })
    end

    it 'can be created and edited' do
      @changeset1.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-19Hollway').operators).to include Operator.find_by_onestop_id!('o-9q8y-SFMTA')
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-19Hollway').routes).to include Route.find_by_onestop_id!('r-9q8y-19Express')
      expect(@changeset1.entities_created_or_updated).to match_array([
        Stop.find_by_onestop_id!('s-9q8yt4b-19Hollway'),
        Operator.find_by_onestop_id!('o-9q8y-SFMTA'),
        Route.find_by_onestop_id!('r-9q8y-19Express'),
        OperatorServingStop.find_by_attributes({ operator_onestop_id: 'o-9q8y-SFMTA', stop_onestop_id: 's-9q8yt4b-19Hollway'}),
        RouteServingStop.find_by_attributes({ route_onestop_id: 'r-9q8y-19Express', stop_onestop_id: 's-9q8yt4b-19Hollway'})
      ])
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
