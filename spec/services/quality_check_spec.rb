describe QualityCheck do
end

describe QualityCheck::GeometryQualityCheck do

  before(:each) do
    @feed, @feed_version = load_feed(feed_version_name: :feed_version_example_issues, import_level: 1)
    @changeset = @feed_version.changesets_imported_from_this_feed_version.first
  end

  # before(:each) do
  #   feed = create(:feed_example)
  #   operator = build(:operator)
  #   route = build(:route)
  #   stop1 = Stop.new(name: 'stop1',
  #                    onestop_id: Faker::OnestopId.stop,
  #                    timezone: 'America/Los_Angeles',
  #                    geometry: Stop::GEOFACTORY.point(-122.353165, 37.936887))
  #   stop2 = Stop.new(name: 'stop2',
  #                    onestop_id: Faker::OnestopId.stop,
  #                    timezone: 'America/Los_Angeles',
  #                    geometry: Stop::GEOFACTORY.point(-122.38666, 37.599787))
  #   route_stop_pattern = RouteStopPattern.new(route: route,
  #                                             stop_pattern: [stop1.onestop_id, stop2.onestop_id],
  #                                             geometry: RouteStopPattern.line_string([
  #                                               [-122.353165, 37.936887],
  #                                               [-122.37, 37.75],
  #                                               [-122.38666, 37.5]
  #                                             ]))
  #   data = {
  #         payload: {
  #           changes: [
  #             {
  #               action: "createUpdate",
  #               feed: feed.as_change
  #             },
  #             {
  #               action: "createUpdate",
  #               operator: operator.as_change
  #             },
  #             {
  #               action: "createUpdate",
  #               route: route.as_change
  #             },
  #             {
  #               action: "createUpdate",
  #               stop: stop1.as_change
  #             },
  #             {
  #               action: "createUpdate",
  #               stop: stop2.as_change
  #             },
  #             {
  #               action: "createUpdate",
  #               route_stop_pattern: route_stop_pattern.as_change
  #             }
  #           ]
  #       }
  #   }
  #   @changeset = Changeset.new(data)
  # end

  context 'checks' do

    it 'checks' do
      # here duplication avoidance on import is implied
      quality_check = QualityCheck::GeometryQualityCheck.new(changeset: @changeset)
      expect(quality_check.check.size).to eq 1
    end

    context 'avoids duplication' do
      it 'avoids duplication during non-import changeset' do
        changeset = create(:changeset, payload: {
          changes: [
            action: 'createUpdate',
            stop: {
              onestopId: 's-9qsfp2212t-stagecoachhotel~casinodemo',
              timezone: 'America/Los_Angeles',
              "geometry": {
                "type": "Point",
                "coordinates": [-120.0, 38.0]
              }
            },
            route_stop_pattern: {
              onestopId: 'r-9qsczp-40-d47aad-75a7ba',
              "geometry": {
                "type": "LineString",
                "coordinates": [[-116.75168, 36.91568],
                                [-116.76147, 36.914941], # tiny tweak here
                                [-116.76821, 36.91489],
                                [-116.76824, 36.90949],
                                [-116.76218, 36.905697]]
              }
            }
          ]
        })
        changeset.apply!
        quality_check = QualityCheck::GeometryQualityCheck.new(changeset: changeset)
        issues = quality_check.check
        expect(issues.size).to eq 3
      end
    end
  end
end
