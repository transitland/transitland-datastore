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
#  identifiers                        :string           default([]), is an Array
#
# Indexes
#
#  #c_stops_cu_in_changeset_id_index   (created_or_updated_in_changeset_id)
#  index_current_stops_on_identifiers  (identifiers)
#  index_current_stops_on_onestop_id   (onestop_id)
#  index_current_stops_on_tags         (tags)
#  index_current_stops_on_updated_at   (updated_at)
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

  context 'served_by' do
    before(:each) do
      @bart = create(:operator, name: 'BART')
      @sfmta = create(:operator, name: 'SFMTA')
      @bart_route = create(:route, operator: @bart)
      @sfmta_route = create(:route, operator: @sfmta)
      @stop_with_both = create(:stop)
      @stop_with_sfmta = create(:stop)
      @stop_with_both.routes << [@bart_route, @sfmta_route]
      @stop_with_both.operators << [@bart, @sfmta]
      @stop_with_sfmta.routes << @sfmta_route
      @stop_with_sfmta.operators << @sfmta
    end

    it 'by operator' do
      expect(Stop.served_by([@sfmta])).to match_array([@stop_with_both, @stop_with_sfmta])
      expect(Stop.served_by([@sfmta.onestop_id])).to match_array([@stop_with_both, @stop_with_sfmta])
      expect(Stop.served_by([@bart])).to match_array([@stop_with_both])
      expect(Stop.served_by([@bart.onestop_id])).to match_array([@stop_with_both])
      expect(Stop.served_by([@sfmta.onestop_id, @bart])).to match_array([@stop_with_both, @stop_with_sfmta])
    end

    it 'by route' do
      expect(Stop.served_by([@sfmta_route])).to match_array([@stop_with_both, @stop_with_sfmta])
      expect(Stop.served_by([@sfmta_route.onestop_id])).to match_array([@stop_with_both, @stop_with_sfmta])
      expect(Stop.served_by([@bart_route])).to match_array([@stop_with_both])
      expect(Stop.served_by([@bart_route.onestop_id])).to match_array([@stop_with_both])
      expect(Stop.served_by([@sfmta_route.onestop_id, @bart_route])).to match_array([@stop_with_both, @stop_with_sfmta])
    end

    it 'by both operator and route' do
      expect(Stop.served_by([@sfmta_route.onestop_id, @bart])).to match_array([@stop_with_both, @stop_with_sfmta])
      expect(Stop.served_by([@sfmta_route, @bart.onestop_id])).to match_array([@stop_with_both, @stop_with_sfmta])
    end
  end

  context 'diff_against' do
    pending 'write some specs'
  end
end
