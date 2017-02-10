describe Api::V1::StopStationsController do
  describe 'GET index' do
    context 'as JSON' do
      context 'with issues' do
        before(:each) do
          @platform_stop_with_issue = create(:stop_platform)
          @issue = Issue.create!(issue_type: 'stop_platform_parent_distance_gap')
          @issue.entities_with_issues.create!(entity: @platform_stop_with_issue, entity_attribute: 'geometry')
          @issue.entities_with_issues.create!(entity: @platform_stop_with_issue.parent_stop, entity_attribute: 'geometry')
        end

        it 'returns stops with station_hierarchy issues' do
          get :index, embed_issues: 'true'
          expect_json({ stop_stations: -> (stops) {
              expect(stops.first[:issues].size).to eq 1
          }})

          get :index, embed_issues: 'false'
          expect_json({ stop_stations: -> (stops) {
              expect(stops.first[:issues]).to be_nil
          }})
        end

        it 'does not return issues that are not station_hierarchy issues' do
          other_issue = Issue.create!(issue_type: 'stop_name')
          other_issue.entities_with_issues.create!(entity: @platform_stop_with_issue, entity_attribute: 'name')

          get :index, embed_issues: 'true'
          expect_json({ stop_stations: -> (stops) {
              expect(stops.first[:issues].size).to eq 1
              expect(Issue.find(stops.first[:issues].first[:id])).to eq @issue
              expect(stops.last[:issues].size).to eq 1
              expect(Issue.find(stops.last[:issues].first[:id])).to eq @issue
          }})
        end
      end
    end
  end
end
