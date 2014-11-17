describe OnestopId do
  it 'fails gracefully when given an invalid geometry' do
    expect {
      OnestopId.new('Retiro Station', '-58.374722 -34.591389')
    }.to raise_error(ArgumentError)

    expect {
      OnestopId.new('Retiro Station', [-58.374722,-34.591389])
    }.to raise_error(ArgumentError)
  end

  context 'validation' do
    it 'must start with "s-" as its 1st component' do
      is_a_valid_onestop_id, errors = OnestopId.valid?('69y7pwu-RetSta')
      expect(is_a_valid_onestop_id).to be false
      expect(errors).to include 'must start with "s-" as its 1st component'
    end

    it 'must include 3 components separated by hyphens ("-")' do
      is_a_valid_onestop_id, errors = OnestopId.valid?('s-69y7pwuRetSta')
      expect(is_a_valid_onestop_id).to be false
      expect(errors).to include 'must include 3 components separated by hyphens ("-")'
    end

    it 'must include a valid geohash as its 2nd component, after "s-"' do
      is_a_valid_onestop_id, errors = OnestopId.valid?('s-69y@7pwu-RetSta')
      expect(is_a_valid_onestop_id).to be false
      expect(errors).to include 'must include a valid geohash as its 2nd component, after "s-"'
    end

    it 'must include only letters and digits in its abbreviated name (the 3rd component)' do
      is_a_valid_onestop_id, errors = OnestopId.valid?('6s-9y7pwu-RetSt#a')
      expect(is_a_valid_onestop_id).to be false
      expect(errors).to include 'must include only letters and digits in its abbreviated name (the 3rd component)'
    end
  end

  context 'generate_unique' do
    it 'never has spaces or symbols' do
      onestop_id = OnestopId.new('Retiro/Station @Platform #1', 'POINT(-58.374722 -34.591389)')
      expect(onestop_id.generate_unique.split(/[\.\# \@\/\\\+]/).count).to eq 1
    end

    it 'includes a GeoHash as its 2nd (of 3) components, with up to 7 characters of precision' do
      onestop_id = OnestopId.new('Retiro Station', 'POINT(-58.374722 -34.591389)')
      expect(onestop_id.generate_unique.split('-').second).to eq '69y7pwu'
    end

    it "when the geometry is a polygon, also includes a GeoHash (of the polygon's centroid)" do
      # TODO: write this
    end

    it 'abbreviates the stop name as the 3rd (of 3) components' do
      onestop_id = OnestopId.new('Retiro Station', 'POINT(-58.374722 -34.591389)')
      expect(onestop_id.generate_unique.split('-').last).to eq 'RetSta'
    end

    it "when given same name and geometry, generates OnestopIDs that don't conflict" do
      existing_stop1 = create(:stop, geometry: 'POINT(-122.434011 37.733595)', name: 'Bosworth + Diamond')
      existing_stop2 = create(:stop, geometry: 'POINT(-122.434011 37.733595)', name: 'Bosworth + Diamond')
      existing_stop3 = create(:stop, geometry: 'POINT(-122.434011 37.733595)', name: 'Bosworth + Diamond')
      existing_onestop_ids = Stop.select(:onestop_id)
      expect(existing_onestop_ids.uniq.length).to eq 3
      onestop_id = OnestopId.new('Bosworth + Diamond', 'POINT(-122.434011 37.733595)')
      expect(existing_onestop_ids).to_not include onestop_id.generate_unique
    end
  end
end
