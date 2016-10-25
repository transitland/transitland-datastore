# == Schema Information
#
# Table name: issues
#
#  id                       :integer          not null, primary key
#  created_by_changeset_id  :integer
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

  it '.from_feed having entities_with_issues' do
    feed_version1 = create(:feed_version_sfmta_6731593)
    stop1 = create(:stop)
    stop1.entities_imported_from_feed.create(feed: feed_version1.feed, feed_version: feed_version1)
    rsp1 = create(:route_stop_pattern)
    rsp1.entities_imported_from_feed.create(feed: feed_version1.feed, feed_version: feed_version1)

    feed_version2 = create(:feed_version_bart)
    stop2 = create(:stop_richmond)
    stop2.entities_imported_from_feed.create(feed: feed_version2.feed, feed_version: feed_version2)
    rsp2 = create(:route_stop_pattern_bart)
    rsp2.entities_imported_from_feed.create(feed: feed_version2.feed, feed_version: feed_version2)

    changeset1 = create(:changeset)
    changeset2 = create(:changeset)

    @test_issue = Issue.create(created_by_changeset: changeset1,
                          issue_type: 'stop_rsp_distance_gap')
    @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: stop1.id, entity_type: 'Stop', issue: @test_issue, entity_attribute: 'geometry')
    @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: rsp1.id, entity_type: 'RouteStopPattern', issue: @test_issue, entity_attribute: 'geometry')
    @other_issue = Issue.create(created_by_changeset: changeset2,
                          issue_type: 'stop_rsp_distance_gap')
    @other_issue.entities_with_issues << EntityWithIssues.new(entity_id: stop2.id, entity_type: 'Stop', issue: @other_issue, entity_attribute: 'geometry')
    @other_issue.entities_with_issues << EntityWithIssues.new(entity_id: rsp2.id, entity_type: 'RouteStopPattern', issue: @other_issue, entity_attribute: 'geometry')

    expect(Issue.from_feed('f-9q8y-sfmta').size).to eq 1
    expect(Issue.from_feed('f-9q9-bart').size).to eq 1
  end

  it '.from_feed having no entities_with_issues' do
    feed1 = create(:feed_sfmta)
    feed2 = create(:feed_bart)
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
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_example_issues, import_level: 1)
      # Issues:
      # 1 - 6: rsp_line_inaccurate
      # 7: distance_calculation_inaccurate (s-9qkxnx40xt-furnacecreekresortdemo & r-9qsb-20-8d5767-6bb5fc)
      # 8: stop_rsp_distance_gap (s-9qscwx8n60-nyecountyairportdemo & r-9qscy-30-a41e99-fcca25)
    end

    context 'entity attributes' do
      before(:each) do
        @rsp = RouteStopPattern.find_by_onestop_id!('r-9qsb-20-8d5767-6bb5fc')
      end

      it '.issues_of_entity' do
        issue_1 = Issue.create!(issue_type: 'rsp_line_inaccurate', details: 'this is a fake geometry issue')
        issue_1.entities_with_issues.create!(entity: @rsp, entity_attribute: 'geometry')
        issue_2 = Issue.create!(issue_type: 'uncategorized', details: 'this is another fake issue without entities_with_issues entity_attribute')
        issue_2.entities_with_issues.create!(entity: @rsp)
        expect(Issue.issues_of_entity(@rsp, entity_attributes: ["stop_distances"])).to match_array([Issue.find(7)])
        expect(Issue.issues_of_entity(@rsp, entity_attributes: ["stop_distances", "dummy"])).to match_array([Issue.find(7)])
        expect(Issue.issues_of_entity(@rsp, entity_attributes: [])).to match_array([issue_2, issue_1, Issue.find(7)])
      end

      it '.entity_outdated_issues' do
        expect(Issue.entity_outdated_issues(@rsp, entity_attributes: [])).to match_array([])
        @rsp.updated_at = 3.minutes.from_now
        expect(Issue.entity_outdated_issues(@rsp, entity_attributes: [])).to match_array([Issue.find(7)])
      end

      it '.entity_outdated_issues entities added to entities_with_issues after issue creation' do
        Issue.find(7).entities_with_issues.create!(entity: Stop.last)
      end
    end

    it 'destroys entities_with_issues when issue destroyed' do
      Issue.find(8).destroy
      expect{Issue.find(8)}.to raise_error(ActiveRecord::RecordNotFound)
      expect{EntityWithIssues.find(10)}.to raise_error(ActiveRecord::RecordNotFound)
      expect{EntityWithIssues.find(11)}.to raise_error(ActiveRecord::RecordNotFound)
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
