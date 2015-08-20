describe GeohashHelpers do
  GEOFACTORY = RGeo::Geographic.simple_mercator_factory
  let (:test_geohash) {'xn76urwe1eqf'}
  let (:test_point) {GEOFACTORY.point(139.76608, 35.68138)}
  # Caltrain Stations
  let (:test_geometries) {
    [
      [-122.2992715, 37.9030588],
      [-122.396742, 37.792976],
      [-122.4474142, 37.72198087],
      [-121.9764, 37.557355],
      [-122.029095, 37.973737],
      [-122.224274, 37.774963],
      [-122.271604, 37.803664],
      [-122.126871, 37.697185],
      [-122.087967, 37.670399],
      [-122.123801, 37.893394],
      [-122.269029, 37.80787],
      [-122.265609, 37.797484],
      [-122.267227, 37.828415],
      [-122.067423, 37.905628],
      [-122.267227, 37.828415],
      [-122.38666, 37.599787],
      [-122.075567, 37.690754],
      [-122.401407, 37.789256],
      [-122.283451, 37.87404],
      [-122.269029, 37.80787],
      [-122.1837911, 37.87836087],
      [-122.419694, 37.765062],
      [-122.2945822, 37.80467476],
      [-122.21244024, 37.71297174],
      [-121.945154, 38.018914],
      [-122.466233, 37.684638],
      [-122.056013, 37.928403],
      [-122.406857, 37.784991],
      [-122.418466, 37.752254],
      [-122.26978, 37.853024],
      [-122.251793, 37.844601],
      [-121.928099, 37.699759],
      [-122.416038, 37.637753],
      [-122.1613112, 37.72261921],
      [-122.0575506, 37.63479954],
      [-122.392612, 37.616035],
      [-122.413756, 37.779528],
      [-122.353165, 37.936887],
      [-122.197273, 37.754006],
      [-122.017867, 37.591208],
      [-122.024597, 38.003275],
      [-122.4690807, 37.70612055],
      [-122.268045, 37.869867],
      [-122.444116, 37.664174],
      [-121.900367, 37.701695],
      [-122.317269, 37.925655],
      [-122.434092, 37.732921]
    ].map { |lon,lat| GEOFACTORY.point(lon, lat)}
  }
  
  it 'encode' do
    expect(GeohashHelpers.encode(test_point, precision=test_geohash.length)).to eq(test_geohash)
  end

  it 'decode' do
    point = GeohashHelpers.decode(test_geohash, decimals=5)
    expect(point.lon).to eq(test_point.lon)
    expect(point.lat).to eq(test_point.lat)
  end

  it 'adjacent' do
    expect(GeohashHelpers.adjacent('9p', :e)).to eq('9r')
    expect(GeohashHelpers.adjacent('9p', :s)).to eq('9n')
    expect(GeohashHelpers.adjacent('9p', :w)).to eq('8z')
    expect(GeohashHelpers.adjacent('9p', :n)).to eq('c0')    
  end

  it 'neighbors' do
    result = GeohashHelpers.neighbors('9p')
    expect(result[:n]).to eq('c0')
    expect(result[:ne]).to eq('c2')
    expect(result[:e]).to eq('9r')
    expect(result[:se]).to eq('9q')
    expect(result[:s]).to eq('9n')
    expect(result[:sw]).to eq('8y')
    expect(result[:w]).to eq('8z')
    expect(result[:nw]).to eq('bb')
    expect(result[:c]).to eq('9p')
  end

  it 'fit' do
    expect(GeohashHelpers.fit(test_geometries)).to eq('9q9')
  end

end
