# == Schema Information
#
# Table name: stops
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string(255)
#  geometry                           :spatial          geometry, 4326
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  name                               :string(255)
#  created_or_updated_in_changeset_id :integer
#  destroyed_in_changeset_id          :integer
#  version                            :integer
#  current                            :boolean
#
# Indexes
#
#  index_stops_on_current          (current)
#  index_stops_on_onestop_id       (onestop_id)
#  stops_cu_in_changeset_id_index  (created_or_updated_in_changeset_id)
#  stops_d_in_changeset_id_index   (destroyed_in_changeset_id)
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

  context 'geometry' do
    it 'can be specified with WKT' do
      stop = create(:stop, geometry: 'POINT(-122.433416 37.732525)')
      expect(Stop.exists?(stop)).to be true
      expect(stop.geometry.to_s).to eq 'POINT (-122.433416 37.732525)'
    end

    it 'can be specified with GeoJSON' do
      stop = create(:stop, geometry: { type: 'Point', coordinates: [-122.433416, 37.732525] })
      expect(Stop.exists?(stop)).to be true
      expect(stop.geometry.to_s).to eq 'POINT (-122.433416 37.732525)'
    end

    it 'can be read as GeoJSON' do
      stop = create(:stop, geometry: { type: 'Point', coordinates: [-122.433416, 37.732525] })
      expect(stop.geometry(as: :geojson)).to eq({ 'type' => 'Point', 'coordinates' => [-122.433416, 37.732525] })
    end
  end

  context 'match_against_existing_or_initialize' do
    it 'if stop with same onestop_id already exists, returns that' do
      stop_with_same_onestop_id = create(:stop)
      stop_with_different_onestop_id = create(:stop)
      returned_stop = Stop.match_against_existing_or_initialize({
        onestop_id: stop_with_same_onestop_id.onestop_id,
      })
      expect(returned_stop.id).to eq stop_with_same_onestop_id.id
    end

    it 'if stop with same name exists within 10 meters, returns that' do
      stop = create(:stop, geometry: 'POINT(-122.1646481752 37.4431429028)', name: 'University Ave. Marguerite')
      other_stop = create(:stop, geometry: 'POINT(-122.1653 37.4436)', name: 'University Ave. Caltrain Northbound')
      returned_stop = Stop.match_against_existing_or_initialize({
        geometry: 'POINT(-122.1646106243 37.4431386436)',
          name: 'University Ave. Marguerite'
      })
      expect(returned_stop.id).to eq stop.id
    end

    it 'if no similar stop exists, creates and returns a new one' do
      stop = create(:stop, geometry: 'POINT(-122.1646481752 37.4431429028)', name: 'University Ave. Marguerite')
      returned_stop = Stop.match_against_existing_or_initialize({
        onestop_id: 's-3v5-Fake',
        geometry: 'POINT(-122.1653 37.4436)',
          name: 'University Ave. Caltrain Northbound'
      })
      returned_stop.save!
      expect(Stop.count).to eq 2
      expect(returned_stop.id).to be > stop.id
    end
  end

  context 'diff_against' do
    pending 'write some specs'
  end
end
