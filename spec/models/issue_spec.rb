# == Schema Information
#
# Table name: issues
#
#  id                       :integer          not null, primary key
#  created_by_changeset_id  :integer          not null
#  resolved_by_changeset_id :integer
#  details                  :string
#  issue_type               :string
#  open                     :boolean          default(TRUE)
#  block_changeset_apply    :boolean          default(FALSE)
#  created_at               :datetime
#  updated_at               :datetime
#

describe Issue do

  it 'can be created' do
    changeset = create(:changeset)
    issue = Issue.new(created_by_changeset: changeset)
  end

  it 'changeset_from_entities' do

  end

  context 'existing issues' do
    before(:each) do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_example_issues, import_level: 1)
    end

    it 'can be resolved' do
      changeset = create(:changeset, payload: {
        changes: [
          action: 'createUpdate',
          issueResolved: 1,
          stop: {
            onestopId: 's-9qscwx8n60-nyecountyairportdemo',
            timezone: 'America/Los_Angeles',
            "geometry": {
              "type": "Point",
              "coordinates": [-116.784582, 36.88845]
            }
          }
        ]
      })
      changeset.apply!
      expect(Issue.first.open).to be false
      expect(Issue.first.resolved_by_changeset).to eq changeset
    end

    context 'find_by_equivalent' do
      before(:each) do
        @test_issue = Issue.new(created_by_changeset: @feed_version.changesets_imported_from_this_feed_version.first,
                              issue_type: 'stop_rsp_distance_gap')
      end

      it 'finds equivalent issue when entities with issues are matching' do
        @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: 1, entity_type: 'Stop', issue: @test_issue, entity_attribute: 'geometry')
        @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: 3, entity_type: 'RouteStopPattern', issue: @test_issue, entity_attribute: 'geometry')
        expect(Issue.find_by_equivalent(@test_issue)).to eq Issue.first
      end

      it 'returns nil when entities with issues are not matching exactly' do
        @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: 1, entity_type: 'Stop', issue: @test_issue, entity_attribute: 'geometry')
        expect(Issue.find_by_equivalent(@test_issue)).to be nil
      end

      it 'returns nil when Issue attributes are not matching' do
        other_issue = Issue.new(created_by_changeset: @feed_version.changesets_imported_from_this_feed_version.first,
                              issue_type: 'stop_position_inaccurate')
        other_issue.entities_with_issues << EntityWithIssues.new(entity_id: 1, entity_type: 'Stop', issue: @test_issue, entity_attribute: 'geometry')
        expect(Issue.find_by_equivalent(other_issue)).to be nil
      end
    end
  end
end
