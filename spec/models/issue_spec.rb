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

  it '.with_type' do
    changeset = create(:changeset)
    Issue.new(created_by_changeset: changeset, issue_type: 'stop_position_inaccurate').save!
    Issue.new(created_by_changeset: changeset, issue_type: 'rsp_line_inaccurate').save!
    expect(Issue.with_type('stop_position_inaccurate,fake').size).to eq 1
    expect(Issue.with_type('stop_position_inaccurate,rsp_line_inaccurate').size).to eq 2
    expect(Issue.with_type('fake1,fake2').size).to eq 0
  end

  it '.from_feed' do
    feed1 = build(:feed_sfmta)
    feed2 = build(:feed_bart)
    changeset1 = create(:changeset, imported_from_feed: feed1)
    changeset2 = create(:changeset, imported_from_feed: feed2)
    Issue.new(created_by_changeset: changeset1, issue_type: 'stop_position_inaccurate').save!
    Issue.new(created_by_changeset: changeset1, issue_type: 'rsp_line_inaccurate').save!
    Issue.new(created_by_changeset: changeset2, issue_type: 'rsp_line_inaccurate').save!
    expect(Issue.from_feed('f-9q8y-sfmta').size).to eq 2
    expect(Issue.from_feed('f-9q9-bart').size).to eq 1
  end

  context 'existing issues' do
    before(:each) do
      Timecop.freeze(3.minutes.ago) do
        @feed, @feed_version = load_feed(feed_version_name: :feed_version_example_issues, import_level: 1)
      end
    end

    it 'can be resolved' do
      changeset = create(:changeset, payload: {
        changes: [
          action: 'createUpdate',
          issuesResolved: [1],
          stop: {
            onestopId: 's-9qscwx8n60-nyecountyairportdemo',
            timezone: 'America/Los_Angeles',
            "geometry": {
              "type": "Point",
              "coordinates": [-116.784582, 36.888446]
            }
          }
        ]
      })
      changeset.apply!
      expect(Issue.find(1).open).to be false
      expect(Issue.find(1).resolved_by_changeset).to eq changeset
    end

    it 'does not apply changeset that does not resolve payload issues_resolved' do
      changeset = create(:changeset, payload: {
        changes: [
          action: 'createUpdate',
          issuesResolved: [2],
          stop: {
            onestopId: 's-9qscwx8n60-nyecountyairportdemo',
            timezone: 'America/Los_Angeles',
            "geometry": {
              "type": "Point",
              "coordinates": [-100.0, 50.0]
            }
          }
        ]
      })
      expect {
        changeset.apply!
      }.to raise_error(Changeset::Error)
    end

    it 'deprecates issues of old feed version imports' do
      load_feed(feed_version: @feed_version, import_level: 1)
      expect(Issue.count).to eq 2
      expect{Issue.find(1)}.to raise_error(ActiveRecord::RecordNotFound)
      expect(Issue.find(3).created_by_changeset_id).to eq 2
    end

    it 'deprecates issues created by older changesets of associated entities' do
      Timecop.freeze(2.minutes.ago) do
        # NOTE: although this changeset would resolve an issue,
        # we are explicitly avoiding that
        changeset = create(:changeset, payload: {
          changes: [
            action: 'createUpdate',
            stop: {
              onestopId: 's-9qscwx8n60-nyecountyairportdemo',
              timezone: 'America/Los_Angeles',
              "geometry": {
                "type": "Point",
                "coordinates": [-116.784582, 36.888446]
              }
            }
          ]
        })
        changeset.apply!
      end
      expect{Issue.find(2)}.to raise_error(ActiveRecord::RecordNotFound)
      expect(Issue.find(4).created_by_changeset_id).to eq 2
    end

    context 'equivalency' do
      before(:each) do
        @test_issue = Issue.new(created_by_changeset: @feed_version.changesets_imported_from_this_feed_version.first,
                              issue_type: 'stop_rsp_distance_gap')
      end

      it 'determines equivalent?' do
        @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: 1, entity_type: 'Stop', issue: @test_issue, entity_attribute: 'geometry')
        @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: 3, entity_type: 'RouteStopPattern', issue: @test_issue, entity_attribute: 'geometry')
        expect(Issue.last.equivalent?(@test_issue)).to be true
      end

      it 'determines not equivalent?' do
        @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: 1, entity_type: 'Stop', issue: @test_issue, entity_attribute: 'geometry')
        expect(Issue.last.equivalent?(@test_issue)).to be false
      end

      it 'finds equivalent issue when entities with issues are matching' do
        @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: 1, entity_type: 'Stop', issue: @test_issue, entity_attribute: 'geometry')
        @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: 3, entity_type: 'RouteStopPattern', issue: @test_issue, entity_attribute: 'geometry')
        expect(Issue.find_by_equivalent(@test_issue)).to eq Issue.last
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
