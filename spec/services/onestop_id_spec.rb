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
      is_a_valid_onestop_id, errors = OnestopId.validate_onestop_id_string('69y7pwu-RetSta', expected_entity_type: 'stop')
      expect(is_a_valid_onestop_id).to be false
      expect(errors).to include 'must start with "s" as its 1st component'
    end

    it 'must include 3 components separated by hyphens ("-")' do
      is_a_valid_onestop_id, errors = OnestopId.validate_onestop_id_string('s-69y7pwuRetSta')
      expect(is_a_valid_onestop_id).to be false
      expect(errors).to include 'must include 3 components separated by hyphens ("-")'
    end

    it 'must include a valid geohash as its 2nd component, after "s-"' do
      is_a_valid_onestop_id, errors = OnestopId.validate_onestop_id_string('s-69y@7pwu-RetSta')
      expect(is_a_valid_onestop_id).to be false
      expect(errors).to include 'must include a valid geohash as its 2nd component'
    end

    it 'must include only letters and digits in its abbreviated name (the 3rd component)' do
      is_a_valid_onestop_id, errors = OnestopId.validate_onestop_id_string('6s-9y7pwu-RetSt#a')
      expect(is_a_valid_onestop_id).to be false
      expect(errors).to include 'must include only letters and digits in its abbreviated name (the 3rd component)'
    end
  end
end
