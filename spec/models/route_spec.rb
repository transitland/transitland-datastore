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
#
# Indexes
#
#  c_route_cu_in_changeset              (created_or_updated_in_changeset_id)
#  index_current_routes_on_operator_id  (operator_id)
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
end
