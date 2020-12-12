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
#  timezone                           :string
#  short_name                         :string
#  website                            :string
#  country                            :string
#  state                              :string
#  metro                              :string
#  edited_attributes                  :string           default([]), is an Array
#
# Indexes
#
#  #c_operators_cu_in_changeset_id_index  (created_or_updated_in_changeset_id)
#  index_current_operators_on_geometry    (geometry) USING gist
#  index_current_operators_on_onestop_id  (onestop_id) UNIQUE
#  index_current_operators_on_tags        (tags)
#  index_current_operators_on_updated_at  (updated_at)
#

describe Operator do
  it 'can be created' do
    operator = create(:operator)
    expect(Operator.exists?(operator.id)).to be true
  end

  it 'can compute a buffered polygon convex hull around only 1 stop' do
    operator = create(:operator)
    operator.stops << create(:stop, geometry: { type: "Point", coordinates: [-73.88031005859375, 40.865756786006806] })
    convex_hull_coordinates = operator.recompute_convex_hull_around_stops[:coordinates]
    rounded_convex_hull_coordinates = convex_hull_coordinates.first.map {|a| a.map { |b| b.round(4) } }
    expected_coordinates = [
      [-73.8794, 40.8658],
      [-73.8803, 40.8651],
      [-73.8812, 40.8658],
      [-73.8803, 40.8664],
      [-73.8794, 40.8658]
    ]
    rounded_convex_hull_coordinates.zip(expected_coordinates).each { |a,b|
      expect(a[0]).to be_within(0.01).of(b[0])
      expect(a[1]).to be_within(0.01).of(b[1])
    }
  end

  it 'can compute a buffered polygon convex hull around only 2 stops' do
    operator = build(:operator, geometry: nil)
    operator.stops << create(:stop, geometry: { type: "Point", coordinates: [-73.88031005859375, 40.865756786006806] })
    operator.stops << create(:stop, geometry: { type: "Point", coordinates: [-73.85833740234374, 40.724364221722716] })
    convex_hull_coordinates = operator.recompute_convex_hull_around_stops[:coordinates]
    expected_coordinates = [
      [-73.8574, 40.7244],
      [-73.8582, 40.7237],
      [-73.8592, 40.7243],
      [-73.8812, 40.8657],
      [-73.8804, 40.8664],
      [-73.8794, 40.8658],
      [-73.8574, 40.7244]
    ]
    convex_hull_coordinates.first.zip(expected_coordinates).each { |a,b|
      expect(a[0]).to be_within(0.01).of(b[0])
      expect(a[1]).to be_within(0.01).of(b[1])
    }
  end

  it 'can recompute convex hull around stops' do
    operator = create(:operator)
    operator.stops << create(:stop, geometry: { type: "Point", coordinates: [-73.88031005859375, 40.865756786006806] })
    operator.stops << create(:stop, geometry: { type: "Point", coordinates: [-73.85833740234374, 40.724364221722716] })
    operator.stops << create(:stop, geometry: { type: "Point", coordinates: [-73.97369384765625, 40.76598152771282] })
    operator.stops << create(:stop, geometry: { type: "Point", coordinates: [-74.0753173828125, 40.73268976628568] })
    operator.stops << create(:stop, geometry: { type: "Point", coordinates: [-73.97369384765625, 40.68063802521456] })
    operator.stops << create(:stop, geometry: { type: "Point", coordinates: [-73.94210815429688, 40.74621655456364] })
    convex_hull_coordinates = operator.recompute_convex_hull_around_stops[:coordinates]
    rounded_convex_hull_coordinates = convex_hull_coordinates.first.map {|a| a.map { |b| b.round(4) } }
    # test response created using http://turfjs.org/static/docs/module-turf_convex.html
    expect(rounded_convex_hull_coordinates).to match_array([
      [-73.9737, 40.6806],
      [-74.0753, 40.7327],
      [-73.8803, 40.8658],
      [-73.8583, 40.7244],
      [-73.9737, 40.6806]
    ])
  end

  it 'destroys OperatorInFeed records' do
    operator = create(:operator)
    feed = create(:feed)
    feed.operators_in_feed.create!(operator: operator, gtfs_agency_id: 'test')
    operator.reload
    expect(operator.operators_in_feed.count).to eq(1)
    expect(feed.reload.operators_in_feed.count).to eq(1)
    payload = {changes: [{action: "destroy", operator: {onestopId: operator.onestop_id}}]}
    changeset = Changeset.create!()
    changeset.change_payloads.create!(payload: payload)
    changeset.apply!
    expect(feed.reload.operators_in_feed.count).to eq(0)
  end

  context '.with_feed' do
    before(:each) {
      @operator1 = create(:operator)
      @operator2 = create(:operator)
      @operator3 = create(:operator)
      @feed1 = create(:feed)
      @feed2 = create(:feed)
      @feed3 = create(:feed)
      OperatorInFeed.create!(feed: @feed1, operator: @operator1)
      OperatorInFeed.create!(feed: @feed2, operator: @operator2)
      OperatorInFeed.create!(feed: @feed2, operator: @operator3)
    }

    it 'returns operators in a feed' do
      expect(Operator.with_feed(@feed1)).to match_array([@operator1])
      expect(Operator.with_feed(@feed2)).to match_array([@operator2, @operator3])
      expect(Operator.with_feed(@feed3)).to match_array([])
    end

    it 'returns operators in feeds' do
      expect(Operator.with_feed([@feed1, @feed2])).to match_array([@operator1, @operator2, @operator3])
    end
  end

  context '.without_feed' do
    before(:each) {
      @operator1 = create(:operator)
      @operator2 = create(:operator)
      @feed1 = create(:feed)
      OperatorInFeed.create!(feed: @feed1, operator: @operator1)
    }

    it 'returns operators with no feed references' do
      expect(Operator.without_feed).to match_array([@operator2])
    end
  end

end
