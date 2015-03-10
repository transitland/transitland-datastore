# == Schema Information
#
# Table name: current_stops
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  geometry                           :geography({:srid geometry, 4326
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  name                               :string
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#
# Indexes
#
#  #c_stops_cu_in_changeset_id_index  (created_or_updated_in_changeset_id)
#  index_current_stops_on_onestop_id  (onestop_id)
#

describe Stop do
  it 'can be created' do
    stop = create(:stop)
    expect(Stop.exists?(stop.id)).to be true
  end

  it "won't have extra spaces in its name" do
    stop = create(:stop, name: ' Main St. Stop ')
    expect(stop.name).to eq 'Main St. Stop'
  end

  context 'geometry' do
    it 'can be specified with WKT' do
      stop = create(:stop, geometry: 'POINT(-122.433416 37.732525)')
      expect(Stop.exists?(stop.id)).to be true
      expect(stop.geometry).to eq({ type: 'Point', coordinates: [-122.433416, 37.732525] })
    end

    it 'can be specified with GeoJSON' do
      geojson = { type: 'Point', coordinates: [-122.433416, 37.732525] }
      stop = create(:stop, geometry: geojson)
      expect(Stop.exists?(stop.id)).to be true
      expect(stop.geometry).to eq geojson
    end

    it 'can be read as GeoJSON (by default)' do
      geojson = { type: 'Point', coordinates: [-122.433416, 37.732525] }
      stop = create(:stop, geometry: geojson)
      expect(stop.geometry).to eq geojson
    end

    it 'can be read as WKT' do
      stop = create(:stop, geometry: { type: 'Point', coordinates: [-122.433416, 37.732525] })
      expect(stop.geometry(as: :wkt).to_s).to eq('POINT (-122.433416 37.732525)')
    end
  end

  context 'diff_against' do
    pending 'write some specs'
  end
end
