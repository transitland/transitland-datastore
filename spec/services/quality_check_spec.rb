describe QualityCheck do
end

describe QualityCheck::GeometryQualityCheck do

  context 'checks' do

    context 'import changeset' do
      it 'checks import' do
        feed, feed_version = load_feed(feed_version_name: :feed_version_example_issues, import_level: 1)
        changeset = feed_version.changesets_imported_from_this_feed_version.first
        quality_check = QualityCheck::GeometryQualityCheck.new(changeset: changeset)
        expect(quality_check.check.size).to be > 1
      end
    end

    context 'non-import changeset' do
      it 'checks changeset' do
        stop1 = create(:stop_richmond_offset)
        stop2 = create(:stop_millbrae)
        route_stop_pattern = create(:route_stop_pattern_bart, stop_distances: [0.0, 37641.4])

        changeset = create(:changeset)
        changeset.create_change_payloads([stop1, stop2, route_stop_pattern])
        changeset.apply!
        quality_check = QualityCheck::GeometryQualityCheck.new(changeset: changeset)
        # duplication avoidance is implied here because two related entities are involved in this issue
        expect(quality_check.check.size).to eq 1
      end

      context 'types' do

        it 'stop distances' do
          feed, feed_version = load_feed(feed_version_name: :feed_version_example_issues, import_level: 1)
          changeset = feed_version.changesets_imported_from_this_feed_version.first
          quality_check = QualityCheck::GeometryQualityCheck.new(changeset: changeset)
          expect(quality_check.check.map(&:issue_type)).to include('distance_calculation_inaccurate')
        end

        it 'stop, rsp distance gap' do
          stop1 = create(:stop_richmond_offset)
          stop2 = create(:stop_millbrae)
          route_stop_pattern = create(:route_stop_pattern_bart, stop_distances: [0.0, 37641.4])

          changeset = create(:changeset)
          changeset.create_change_payloads([stop1, stop2, route_stop_pattern])
          changeset.apply!
          quality_check = QualityCheck::GeometryQualityCheck.new(changeset: changeset)
          expect(quality_check.check.map(&:issue_type)).to include('stop_rsp_distance_gap')
        end

        it 'finds consecutive stops with too close geometries' do
          stop1 = create(:stop, geometry: 'POINT(-122.46 37.6)')
          stop2 = create(:stop, geometry: 'POINT(-122.433416 37.732525)')
          stop3 = create(:stop, geometry: 'POINT(-122.433416 37.732525)')
          stop4 = create(:stop, geometry: 'POINT(-122.41 37.7)')
          # add in fake stop distances
          route_stop_pattern = create(:route_stop_pattern, stop_pattern: [stop1.onestop_id, stop2.onestop_id, stop3.onestop_id, stop4.onestop_id], stop_distances: [0.0,1.0,2.0,3.0])
          changeset = create(:changeset)
          changeset.create_change_payloads([stop1, stop2, stop3, stop4, route_stop_pattern])
          changeset.apply!
          expect(Issue.where(issue_type: 'rsp_stops_too_close').size).to be >= 1
        end
      end

      it 'recomputed attributes' do
        stop1 = create(:stop_richmond_offset)
        stop2 = create(:stop_millbrae)
        route_stop_pattern = create(:route_stop_pattern_bart, stop_distances: [0.0, 37641.4])
        changeset = create(:changeset, payload: {
          changes: [
            {
              action: 'createUpdate',
              routeStopPattern: {
                onestopId: 'r-9q8y-richmond~dalycity~millbrae-e8fb80-61d4dc',
                stopPattern: ['s-9q8zzf1nks-richmond','s-9q8vzhbf8h-millbrae'],
                geometry: {
                  type: "LineString",
                  coordinates: [[-122.38666, 37.599787],[-122.353165, 37.936887]]
                }
              }
            }
          ]
        })
        changeset.apply!
        quality_check = QualityCheck::GeometryQualityCheck.new(changeset: changeset)
        expect(quality_check.check.map(&:issue_type)).to include('distance_calculation_inaccurate')
      end
    end
  end
end
