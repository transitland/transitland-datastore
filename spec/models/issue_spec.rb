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
      @changeset1 = create(:changeset)
      @stop1 = create(:stop, onestop_id: "s-9qkxnx40xt-furnacecreekresortdemo",
                    name: 'Furnace Creek Resort (Demo)',
                    geometry: Stop::GEOFACTORY.point(-117.133162, 36.425288),
                    timezone: "America/Los_Angeles",
                    created_or_updated_in_changeset_id: @changeset1.id)
      @stop2 = create(:stop, onestop_id: "s-9qscv9zzb5-bullfrogdemo",
                    name: 'Bullfrog (Demo)',
                    geometry:  Stop::GEOFACTORY.point(-116.81797, 36.88108),
                    timezone: "America/Los_Angeles",
                    created_or_updated_in_changeset_id: @changeset1.id)
      @stop3 = create(:stop, onestop_id: "s-9qscwx8n60-nyecountyairportdemo",
                    name: 'Nye County Airport (Demo)', geometry: Stop::GEOFACTORY.point(-116.784582, 36.868446),
                    timezone: "America/Los_Angeles",
                    created_or_updated_in_changeset_id: @changeset1.id)
      interpolated_rsp = create(:route_stop_pattern)
      @rsp1 = create(:route_stop_pattern, stop_pattern: ["s-9qscv9zzb5-bullfrogdemo", "s-9qkxnx40xt-furnacecreekresortdemo"],
                    geometry: RouteStopPattern.line_string([[-117.13316, 36.42529], [-116.81797, 36.88108]]),
                    stop_distances: [58023.5, 0.0],
                    created_or_updated_in_changeset_id: @changeset1.id)
      @rsp2 = create(:route_stop_pattern, stop_pattern: ["s-9qsfp2212t-stagecoachhotel~casinodemo", "s-9qscwx8n60-nyecountyairportdemo"],
                    geometry: RouteStopPattern.line_string([[-116.75168, 36.91568], [-116.77458, 36.90645], [-116.78458, 36.88845]]),
                    stop_distances: [0.0, 4475.2],
                    created_or_updated_in_changeset_id: @changeset1.id)
      @rsp_line_inaccurate_issue = Issue.create!(issue_type: 'rsp_line_inaccurate', details: 'rsp line wrong.', created_by_changeset: @changeset1)
      @rsp_line_inaccurate_issue.entities_with_issues.create!(entity: interpolated_rsp, entity_attribute: 'geometry')
      @distance_calc_issue = Issue.create!(issue_type: 'distance_calculation_inaccurate', details: 'the stop distances are wrong.', created_by_changeset: @changeset1)
      @distance_calc_issue.entities_with_issues.create!(entity: @rsp1, entity_attribute: 'stop_distances')
      @distance_calc_issue.entities_with_issues.create!(entity: @stop1, entity_attribute: 'geometry')
      @distance_calc_issue.entities_with_issues.create!(entity: @stop2, entity_attribute: 'geometry')
      @stop_rsp_distance_gap_issue = Issue.create!(issue_type: 'stop_rsp_distance_gap', details: 'stop rsp distance gap.', created_by_changeset: @changeset1)
      @stop_rsp_distance_gap_issue.entities_with_issues.create!(entity: @rsp2, entity_attribute: 'geometry')
      @stop_rsp_distance_gap_issue.entities_with_issues.create!(entity: @stop3, entity_attribute: 'geometry')
    end

    context 'entity attributes' do
      it '.issues_of_entity' do
        issue_1 = Issue.create!(issue_type: 'rsp_line_inaccurate', details: 'this is a fake geometry issue')
        issue_1.entities_with_issues.create!(entity: @rsp1, entity_attribute: 'geometry')
        issue_2 = Issue.create!(issue_type: 'other', details: 'this is another fake issue without entities_with_issues entity_attribute')
        issue_2.entities_with_issues.create!(entity: @rsp1)
        expect(Issue.issues_of_entity(@rsp1, entity_attributes: ["stop_distances"])).to match_array([Issue.find(@distance_calc_issue.id)])
        expect(Issue.issues_of_entity(@rsp1, entity_attributes: ["stop_distances", "dummy"])).to match_array([Issue.find(@distance_calc_issue.id)])
        expect(Issue.issues_of_entity(@rsp1, entity_attributes: [])).to match_array([issue_2, issue_1, Issue.find(@distance_calc_issue.id)])
      end
    end

    it 'destroys entities_with_issues when issue destroyed' do
      Issue.find(@stop_rsp_distance_gap_issue.id).destroy
      expect{Issue.find(@stop_rsp_distance_gap_issue.id)}.to raise_error(ActiveRecord::RecordNotFound)
      expect{EntityWithIssues.find(10)}.to raise_error(ActiveRecord::RecordNotFound)
      expect{EntityWithIssues.find(11)}.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'equivalency' do
      before(:each) do
        @test_issue = Issue.new(created_by_changeset: @changeset1,
                              issue_type: 'stop_rsp_distance_gap')
      end

      it 'determines equivalent?' do
        @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: @stop3.id, entity_type: 'Stop', issue: @test_issue, entity_attribute: 'geometry')
        @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: @rsp2.id, entity_type: 'RouteStopPattern', issue: @test_issue, entity_attribute: 'geometry')
        expect(@stop_rsp_distance_gap_issue.equivalent?(@test_issue)).to be true
      end

      it 'determines not equivalent? when entity attribute is different' do
        @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: @stop3.id, entity_type: 'Stop', issue: @test_issue, entity_attribute: 'name')
        @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: @rsp2.id, entity_type: 'RouteStopPattern', issue: @test_issue, entity_attribute: 'geometry')
        expect(@stop_rsp_distance_gap_issue.equivalent?(@test_issue)).to be false
      end

      it 'determines not equivalent? when entities with issues are not matching' do
        @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: @stop1.id, entity_type: 'Stop', issue: @test_issue, entity_attribute: 'geometry')
        @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: @rsp2.id, entity_type: 'RouteStopPattern', issue: @test_issue, entity_attribute: 'geometry')
        expect(@stop_rsp_distance_gap_issue.equivalent?(@test_issue)).to be false
      end

      it 'finds equivalent issue when entities with issues are matching' do
        @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: @stop3.id, entity_type: 'Stop', issue: @test_issue, entity_attribute: 'geometry')
        @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: @rsp2.id, entity_type: 'RouteStopPattern', issue: @test_issue, entity_attribute: 'geometry')
        expect(Issue.find_by_equivalent(@test_issue)).to eq @stop_rsp_distance_gap_issue
      end

      it 'returns nil when entities with issues are not matching exactly' do
        @test_issue.entities_with_issues << EntityWithIssues.new(entity_id: @stop1.id, entity_type: 'Stop', issue: @test_issue, entity_attribute: 'geometry')
        expect(Issue.find_by_equivalent(@test_issue)).to be nil
      end

      it 'returns nil when Issue attributes are not matching' do
        other_issue = Issue.new(created_by_changeset: @changeset1,
                              issue_type: 'stop_position_inaccurate')
        other_issue.entities_with_issues << EntityWithIssues.new(entity_id: @stop3.id, entity_type: 'Stop', issue: @test_issue, entity_attribute: 'geometry')
        expect(Issue.find_by_equivalent(other_issue)).to be nil
      end
    end
  end
end
