describe TyrService do
  it 'should work for one location' do
    VCR.use_cassette('tyr_one_location') do
      locations = [
        {
          lat: 37.775692,
          lon: -122.413601
        }
      ]
      response = TyrService.locate(locations: locations)
      expect(response).to eq [
        {
          input_lon: -122.413601,
          input_lat: 37.775692,
          ways: [{
            correlated_lon: -122.413601,
            way_id: 8917801,
            correlated_lat: 37.775692
          }]
        }
      ]
    end
  end

  it 'should work for two locations' do
    VCR.use_cassette('tyr_two_locations') do
      locations = [
        {
          lat: 37.775692,
          lon: -122.413601
        }, {
          lat: 40.74455,
          lon: -73.990472
        }
      ]
      response = TyrService.locate(locations: locations)
      expect(response).to eq [
        {
          input_lon: -122.413601,
          input_lat: 37.775692,
          ways: [{
            correlated_lon: -122.413601,
            way_id: 8917801,
            correlated_lat: 37.775692
          }]
        },{
          input_lon: -73.990472,
          input_lat: 40.74455,
          ways: [{
            correlated_lon: -73.990472,
            way_id: 5671311,
            correlated_lat: 40.74455
          }]
        }
      ]
    end
  end
end
