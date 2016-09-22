describe IsAnEntityImportedFromFeeds do
  before(:each) do
    feed = create(:feed_bart)
    @stop = create(:stop_richmond)
    @route_stop_pattern = create(:route_stop_pattern_bart)
    changeset = create(:changeset, imported_from_feed: feed)
    issue1 = Issue.new(created_by_changeset: changeset, issue_type: 'distance_calculation_inaccurate')
    issue1.entities_with_issues << EntityWithIssues.new(entity_id: 1, entity_type: 'RouteStopPattern', issue: issue1, entity_attribute: 'stop_distances')
    issue1.entities_with_issues << EntityWithIssues.new(entity_id: 1, entity_type: 'Stop', issue: issue1, entity_attribute: 'geometry')
    issue2 = Issue.new(created_by_changeset: changeset, issue_type: 'rsp_line_inaccurate')
    issue2.entities_with_issues << EntityWithIssues.new(entity_id: 1, entity_type: 'RouteStopPattern', issue: issue2, entity_attribute: 'geometry')
    issue1.save!
    issue2.save!
  end

  it 'destroys entities_with_issues and parent issues when associated entities are destroyed' do
    @stop.destroy
    expect{Issue.find(1)}.to raise_error(ActiveRecord::RecordNotFound)
    expect{EntityWithIssues.find(1)}.to raise_error(ActiveRecord::RecordNotFound)
    expect{EntityWithIssues.find(2)}.to raise_error(ActiveRecord::RecordNotFound)
    expect(Issue.count).to eq 1
  end

  it 'destroys entities_with_issues, parent issues, and parent issues\' children entities_with_issues' do
    @route_stop_pattern.destroy
    expect(Issue.count).to eq 0
    expect(EntityWithIssues.count).to eq 0
  end
end
