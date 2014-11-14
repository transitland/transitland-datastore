# == Schema Information
#
# Table name: stops
#
#  id         :integer          not null, primary key
#  onestop_id :string(255)
#  geometry   :spatial          geometry, 4326
#  tags       :hstore
#  created_at :datetime
#  updated_at :datetime
#  name       :string(255)
#
# Indexes
#
#  index_stops_on_onestop_id  (onestop_id)
#

describe Stop do
  it 'can be created' do
    stop = create(:stop)
    expect(Stop.exists?(stop)).to be true
  end

  it "won't have extra spaces in its name" do
    stop = create(:stop, name: ' Main St. Stop ')
    expect(stop.name).to eq 'Main St. Stop'
  end

  context 'match_against_existing_stop_or_create' do
    it 'if stop with same onestop_id already exists, returns that' do
      stop_with_same_onestop_id = create(:stop)
      stop_with_different_onestop_id = create(:stop)
      returned_stop = Stop.match_against_existing_stop_or_create({
        onestop_id: stop_with_same_onestop_id.onestop_id,
      })
      expect(returned_stop.id).to eq stop_with_same_onestop_id.id
    end

    it 'if stop with same name exists within 10 meters, returns that' do
      stop = create(:stop, geometry: 'POINT(-122.1646481752 37.4431429028)', name: 'University Ave. Marguerite')
      other_stop = create(:stop, geometry: 'POINT(-122.1653 37.4436)', name: 'University Ave. Caltrain Northbound')
      returned_stop = Stop.match_against_existing_stop_or_create({
        geometry: 'POINT(-122.1646106243 37.4431386436)',
          name: 'University Ave. Marguerite'
      })
      expect(returned_stop.id).to eq stop.id
    end

    it 'if no similar stop exists, creates and returns a new one' do
      stop = create(:stop, geometry: 'POINT(-122.1646481752 37.4431429028)', name: 'University Ave. Marguerite')
      returned_stop = Stop.match_against_existing_stop_or_create({
        geometry: 'POINT(-122.1653 37.4436)',
          name: 'University Ave. Caltrain Northbound'
      })
      expect(Stop.count).to eq 2
      expect(returned_stop.id).to be > stop.id
    end
  end
end
