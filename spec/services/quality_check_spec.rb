describe QualityCheck do
end

describe QualityCheck::GeometryQualityCheck do

  context 'checks' do

    context 'non-import changeset' do
      it 'checks changeset' do
        stop1 = create(:stop_richmond_offset)
        stop2 = create(:stop_millbrae)
        route_stop_pattern = create(:route_stop_pattern_bart, stop_distances: [0.0, 37641.4])

        changeset = create(:changeset)
        changeset.create_change_payloads([stop1, stop2, route_stop_pattern])
        # we'll ignore the typical issue cycle within changeset.apply!
        changeset.change_payloads.each do |change_payload|
          change_payload.apply_change
        end
        changeset.update(applied: true, applied_at: Time.now)
        quality_check = QualityCheck::GeometryQualityCheck.new(changeset: changeset)
        # issue duplication avoidance is implied here because multiple entities are involved in this issue
        expect(quality_check.check.size).to eq 1
      end

      context 'types' do

        it 'stop distances' do
          stop1 = create(:stop, geometry: 'POINT(-116.81797 36.88108)')
          stop2 = create(:stop, geometry: 'POINT(-117.133162 36.425288)')
          route_stop_pattern = create(:route_stop_pattern, stop_pattern: [stop1.onestop_id, stop2.onestop_id], geometry: 'LINESTRING (-117.13316 36.42529, -116.81797 36.88108)')
          route_stop_pattern.update_column(:stop_distances, Geometry::TLDistances.new(route_stop_pattern).calculate_distances)
          changeset = create(:changeset)
          changeset.create_change_payloads([route_stop_pattern])
          # we'll ignore the typical issue cycle within changeset.apply! so we can directly test GeometryQualityCheck
          changeset.change_payloads.each do |change_payload|
            change_payload.apply_change
          end

          quality_check = QualityCheck::GeometryQualityCheck.new(changeset: changeset)
          expect(quality_check.check.map(&:issue_type)).to include('distance_calculation_inaccurate')
        end

        it 'stop, rsp distance gap' do
          stop1 = create(:stop_richmond_offset)
          stop2 = create(:stop_millbrae)
          route_stop_pattern = create(:route_stop_pattern_bart, stop_distances: [0.0, 37641.4])

          changeset = create(:changeset)
          changeset.create_change_payloads([stop1, stop2, route_stop_pattern])
          # we'll ignore the typical issue cycle within changeset.apply!
          changeset.change_payloads.each do |change_payload|
            change_payload.apply_change
          end
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
    end
  end
end
