describe UpdateComputedAttributes::GeometryUpdateComputedAttributes do
  context 'rsp stop distances' do
    it 'avoids duplication of rsp distance calculation' do
      create(:stop_richmond_offset)
      create(:stop_millbrae)
      create(:route_stop_pattern_bart)
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9q8zzf1nks-richmond',
              timezone: 'America/Los_Angeles',
              name: 'Richmond',
              geometry: { type: "Point", coordinates: [-122.353165, 37.936887] }
            },
            stop: {
              onestopId: 's-9q8vzhbf8h-millbrae',
              timezone: 'America/Los_Angeles',
              name: 'Millbrae',
              geometry: { type: "Point", coordinates: [-122.38266, 37.599487] }
            }
          },
          {
            action: 'createUpdate',
            routeStopPattern: {
              onestopId: 'r-9q8y-richmond~dalycity~millbrae-e8fb80-61d4dc',
              stopPattern: ['s-9q8zzf1nks-richmond', 's-9q8vzhbf8h-millbrae'],
              geometry: { type: "LineString", coordinates: [[-122.351529, 37.937750], [-122.38666, 37.599787]] }
            }
          }
        ]
      })
      changeset.change_payloads.each do |change_payload|
        change_payload.apply_change
      end
      geometry_updater = UpdateComputedAttributes::GeometryUpdateComputedAttributes.new(changeset: changeset)
      expect(geometry_updater.update_computed_attributes[1]).to eq [1,0]
    end
  end
end
