# == Schema Information
#
# Table name: current_operators
#
#  id                                 :integer          not null, primary key
#  name                               :string
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  onestop_id                         :string
#  geometry                           :geography({:srid geometry, 4326
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  identifiers                        :string           default([]), is an Array
#  timezone                           :string
#  short_name                         :string
#  website                            :string
#  country                            :string
#  state                              :string
#  metro                              :string
#
# Indexes
#
#  #c_operators_cu_in_changeset_id_index   (created_or_updated_in_changeset_id)
#  index_current_operators_on_geometry     (geometry)
#  index_current_operators_on_identifiers  (identifiers)
#  index_current_operators_on_onestop_id   (onestop_id) UNIQUE
#  index_current_operators_on_tags         (tags)
#  index_current_operators_on_updated_at   (updated_at)
#

describe Operator do
  it 'can be created' do
    operator = create(:operator)
    expect(Operator.exists?(operator.id)).to be true
  end

  it 'can be found by identifier and/or name' do
    bart = create(:operator, name: 'BART', identifiers: ['Bay Area Rapid Transit'])
    sfmta = create(:operator, name: 'SFMTA')
    expect(Operator.with_identifier('Bay Area Rapid Transit')).to match_array([bart])
    expect(Operator.with_identifier_or_name('BART')).to match_array([bart])
    expect(Operator.with_identifier('SFMTA')).to be_empty
    expect(Operator.with_identifier_or_name('SFMTA')).to match_array([sfmta])
  end

  it 'can recompute convex hull around stops' do
    operator = create(:operator)
    operator.stops << create(:stop, geometry: { type: "Point", coordinates: [-73.88031005859375, 40.865756786006806] })
    operator.stops << create(:stop, geometry: { type: "Point", coordinates: [-73.85833740234374, 40.724364221722716] })
    operator.stops << create(:stop, geometry: { type: "Point", coordinates: [-73.97369384765625, 40.76598152771282] })
    operator.stops << create(:stop, geometry: { type: "Point", coordinates: [-74.0753173828125, 40.73268976628568] })
    operator.stops << create(:stop, geometry: { type: "Point", coordinates: [-73.97369384765625, 40.68063802521456] })
    operator.stops << create(:stop, geometry: { type: "Point", coordinates: [-73.94210815429688, 40.74621655456364] })
    # test response created using http://turfjs.org/static/docs/module-turf_convex.html
    expect(operator.recompute_convex_hull_around_stops).to eq({
      coordinates: [
        [
          [-73.97369384765625, 40.68063802521456],
          [-74.07531738281251, 40.73268976628566],
          [-73.88031005859375, 40.8657567860068],
          [-73.85833740234374, 40.7243642217227],
          [-73.97369384765625, 40.68063802521456]
        ]
      ],
      type: "Polygon"
    })
  end

end
