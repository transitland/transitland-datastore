describe ConflateStopsWithOsmWorker do
  before(:each) do
    @glen_park = create(:stop, geometry: 'POINT(-122.433416 37.732525)', name: 'Glen Park')
    @bosworth_diamond = create(:stop, geometry: 'POINT(-122.434011 37.733595)', name: 'Bosworth + Diamond')
    @metro_embarcadero = create(:stop, geometry: 'POINT(-122.396431 37.793152)', name: 'Metro Embarcadero')
    @gilman_paul_3rd = create(:stop, geometry: 'POINT(-122.395644 37.722413)', name: 'Gilman + Paul + 3rd St.')
  end

  it 'will call the Tyr service and put osm_way_id into tags for the right Stop models' do
    allow(TyrService).to receive(:locate).and_return([
      {
        input_lon: -122.413601,
        input_lat: 37.775692,
        node: nil,
        edges: [
          {
            correlated_lon: -122.413601,
            way_id: 8917801,
            correlated_lat: 37.775692,
            side_of_street: "right",
            percent_along: .63
          },
          {
            correlated_lon: -122.413601,
            way_id: 8917801,
            correlated_lat: 37.775692,
            side_of_street: "left",
            percent_along: .37
          }
        ]
      },
      {
        input_lon: -122.396431,
        input_lat: 37.793152,
        node: nil,
        edges: [
          {
            correlated_lon: -122.413601,
            way_id: 8917802,
            correlated_lat: 37.775692
            side_of_street: "right",
            percent_along: .82
          },
          {
            correlated_lon: -122.413601,
            way_id: 8917802,
            correlated_lat: 37.775692
            side_of_street: "left",
            percent_along: .18
          }
        ]
      }
    ])
    worker = ConflateStopsWithOsmWorker.new
    worker.perform([@bosworth_diamond.id, @metro_embarcadero.id])
    expect(@bosworth_diamond.reload.tags).to eq({ 'osm_way_id' => '8917801' })
    expect(@metro_embarcadero.reload.tags).to eq({ 'osm_way_id' => '8917802' })
    expect(@glen_park.reload.tags).to be_blank
    expect(@gilman_paul_3rd.reload.tags).to be_blank
  end
end
