# == Schema Information
#
# Table name: current_routes
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  name                               :string
#  tags                               :hstore
#  operator_id                        :integer
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#  geometry                           :geography({:srid geometry, 4326
#  vehicle_type                       :integer
#  color                              :string
#  edited_attributes                  :string           default([]), is an Array
#  wheelchair_accessible              :string           default("unknown")
#  bikes_allowed                      :string           default("unknown")
#
# Indexes
#
#  c_route_cu_in_changeset                        (created_or_updated_in_changeset_id)
#  index_current_routes_on_bikes_allowed          (bikes_allowed)
#  index_current_routes_on_geometry               (geometry) USING gist
#  index_current_routes_on_onestop_id             (onestop_id) UNIQUE
#  index_current_routes_on_operator_id            (operator_id)
#  index_current_routes_on_tags                   (tags)
#  index_current_routes_on_updated_at             (updated_at)
#  index_current_routes_on_vehicle_type           (vehicle_type)
#  index_current_routes_on_wheelchair_accessible  (wheelchair_accessible)
#

describe Route do
  it 'can be created' do
    route = create(:route)
    expect(Route.exists?(route.id)).to be true
  end

  it 'its geometry can be a multi-line string' do
    geojson = {
      type: 'MultiLineString',
      coordinates: [
        [[-73.87481689453125, 40.88860081193033],[ -73.9764404296875, 40.763901280945866],[ -73.94622802734375, 40.686886382151116],[ -73.9544677734375, 40.61186744303007]],
        [[-74.1851806640625,40.81588791441588],[-74.00665283203124,40.83251504043271],[-73.948974609375,40.7909394098518],[-73.8006591796875,40.751418432997426],[-73.4326171875,40.79301881008675]]
      ]
    }
    route = create(:route, geometry: geojson)
    expect(Route.exists?(route.id)).to be true
    expect(route.geometry).to eq geojson
  end

  it 'can be found by operator' do
    bart = create(:operator, name: 'BART')
    sfmta = create(:operator, name: 'SFMTA')
    route1 = create(:route, operator: bart)
    route2 = create(:route, operator: sfmta)
    expect(Route.operated_by(bart)).to match_array([route1])
    expect(Route.operated_by(sfmta.onestop_id)).to match_array([route2])
  end

  context 'within bbox' do
    before(:each) do
      point = Stop::GEOFACTORY.point(-122.0, 35.0)
      stop = create(:stop, geometry: point.to_s)
      geojson = {
        type: 'MultiLineString',
        coordinates: [
          [[-73.87481689453125, 40.88860081193033],[ -73.9764404296875, 40.763901280945866],[ -73.94622802734375, 40.686886382151116],[ -73.9544677734375, 40.61186744303007]],
          [[-74.1851806640625,40.81588791441588],[-74.00665283203124,40.83251504043271],[-73.948974609375,40.7909394098518],[-73.8006591796875,40.751418432997426],[-73.4326171875,40.79301881008675]]
        ]
      }
      @route = create(:route, geometry: geojson)
      create(:route_serving_stop, route: @route, stop: stop)
      @bbox_should_contain_stop_not_geom = [-121.0,34.0,-123.0,36.0]
      @bbox_should_neither_contain_stop_nor_geom = [-125.0,34.0,-123.0,36.0]
      @bbox_should_contain_geom_only = [-73.87481689453125,40.88860081193033,-73.94622802734375,40.686886382151116]
    end

    it 'has a stop within bbox' do
      expect(Route.stop_within_bbox(@bbox_should_contain_stop_not_geom)).to match_array([@route])
      expect(Route.stop_within_bbox(@bbox_should_neither_contain_stop_nor_geom)).to match_array([])
      expect(Route.stop_within_bbox(@bbox_should_contain_geom_only)).to match_array([])
    end

    it 'has geometry within bbox' do
      expect(Route.geometry_within_bbox(@bbox_should_contain_stop_not_geom)).to match_array([])
      expect(Route.geometry_within_bbox(@bbox_should_neither_contain_stop_nor_geom)).to match_array([])
      expect(Route.geometry_within_bbox(@bbox_should_contain_geom_only)).to match_array([@route])
    end
  end

  context '.where_vehicle_type' do
    before(:each) do
      @route1 = create(:route, vehicle_type: 'metro')
      @route2 = create(:route, vehicle_type: 'bus')
      @route3 = create(:route, vehicle_type: 'high_speed_rail_service')
    end

    it 'accepts string vehicle types' do
      expect(Route.where_vehicle_type('metro')).to match_array([@route1])
    end

    it 'accepts integer vehicle types' do
      expect(Route.where_vehicle_type(3)).to match_array([@route2])
    end

    it 'accepts a mix of string and integer vehicle_types' do
      expect(Route.where_vehicle_type(['metro', 3])).to match_array([@route1, @route2])
    end

    it 'fails when invalid vehicle_type' do
      expect{ Route.where_vehicle_type('unicycle') }.to raise_error(KeyError)
    end

    it 'accepts parameterized strings' do
      expect(Route.where_vehicle_type('high_speed_rail_service')).to match_array([@route3])
      expect(Route.where_vehicle_type('High Speed Rail Service')).to match_array([@route3])
    end

  end

  context '.where_serves' do
    before(:each) do
      @stop1, @stop2, @stop3 = create_list(:stop, 3)
      @route1, @route2, @route3 = create_list(:route, 3)
      @route1.routes_serving_stop.create!(stop: @stop1)
      @route1.routes_serving_stop.create!(stop: @stop2)
      @route2.routes_serving_stop.create!(stop: @stop2)
      @route3.routes_serving_stop.create!(stop: @stop3)
    end

    it 'finds routes serving a single stop' do
      expect(Route.where_serves(@stop1)).to match_array([@route1])
      expect(Route.where_serves(@stop2)).to match_array([@route1, @route2])
      expect(Route.where_serves(@stop3)).to match_array([@route3])
    end

    it 'finds routes serving multiple stops' do
      expect(Route.where_serves([@stop1, @stop2, @stop3])).to match_array([@route1, @route2, @route3])
    end

    it 'finds routes serving stop onestop id' do
      expect(Route.where_serves(@stop1.onestop_id)).to match_array([@route1])
    end
  end

  context 'validate route color' do
    before(:each) do
      @route = create(:route)
    end

    it 'validates true an acceptable color' do
      @route.color = 'FFFF33'
      expect(@route.valid?).to be true
      expect(@route.errors).to match_array([])

      @route.color = ''
      expect(@route.valid?).to be true
      expect(@route.errors).to match_array([])
    end

    it 'validates false a color with the wrong length' do
      @route.color = 'AAA'
      expect(@route.valid?).to be false
      expect(@route.errors.messages[:color]).to include 'invalid color'
    end

    it 'validates false a color with lower case letters' do
      @route.color = 'FFaF33'
      expect(@route.valid?).to be false
      expect(@route.errors.messages[:color]).to include 'invalid color'
    end

    it 'validates false a color with the wrong characters' do
      @route.color = 'FF%F33'
      expect(@route.valid?).to be false
      expect(@route.errors.messages[:color]).to include 'invalid color'
    end
  end
end
