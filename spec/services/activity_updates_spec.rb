describe ActivityUpdates do
  it 'lists changesets created' do
    user = create(:user)
    Timecop.freeze(3.minutes.ago) do
      @c2 = create(:changeset, user: user)
    end
    Timecop.freeze(5.minutes.ago) do
      @c1 = create(:changeset, user: user)
    end
    expect(ActivityUpdates.updates_since.map {|u| u[:id] }).to eq([
      "c-#{@c2.id}-created",
      "c-#{@c1.id}-created",
    ])
    expect(ActivityUpdates.updates_since.map {|u| u[:entity_id] }).to eq([
      @c2.id,
      @c1.id
    ])
    expect(ActivityUpdates.updates_since.map {|u| u[:entity_type] }).to eq([
      "changeset",
      "changeset",
    ])
    expect(ActivityUpdates.updates_since.map {|u| u[:entity_action] }).to eq([
      "created",
      "created"
    ])
    expect(ActivityUpdates.updates_since.map {|u| u[:by_user_id] }).to eq([
      User.first.id,
      User.first.id
    ])
    expect(ActivityUpdates.updates_since.map {|u| u[:note] }).to eq([
      "Changeset ##{@c2.id} created. Includes notes: #{@c2.notes}",
      "Changeset ##{@c1.id} created. Includes notes: #{@c1.notes}"
    ])
    expect(ActivityUpdates.updates_since[0][:at_datetime]).to be_within(1.second).of(@c2.created_at)
    expect(ActivityUpdates.updates_since[1][:at_datetime]).to be_within(1.second).of(@c1.created_at)
  end

  it 'lists changesets updated' do
    Timecop.travel(5.minutes.ago) do
      @c1 = create(:changeset)
    end
    Timecop.travel(3.minutes.ago) do
      @c2 = create(:changeset)
    end
    @c1.update(notes: 'new note')
    expect(ActivityUpdates.updates_since.map {|u| u[:id] }).to eq([
      "c-#{@c1.id}-updated",
      "c-#{@c2.id}-created",
      "c-#{@c1.id}-created"
    ])
    expect(ActivityUpdates.updates_since.map {|u| u[:entity_type] }).to eq([
      "changeset",
      "changeset",
      "changeset"
    ])
    expect(ActivityUpdates.updates_since.map {|u| u[:entity_action] }).to eq([
      "updated",
      "created",
      "created"
    ])
    expect(ActivityUpdates.updates_since.map {|u| u[:note] }).to eq([
      "Changeset ##{@c1.id} updated. Includes notes: #{@c1.notes}",
      "Changeset ##{@c2.id} created. Includes notes: #{@c2.notes}",
      "Changeset ##{@c1.id} created. Includes notes: #{@c1.notes}"
    ])
  end

  it 'lists changesets applied' do
    Timecop.travel(5.minutes.ago) do
      @c1 = create(:changeset)
    end
    Timecop.travel(3.minutes.ago) do
      @c1.update_column(:applied, true)
      @c1.update_column(:applied_at, Time.now)
    end
    expect(ActivityUpdates.updates_since.map {|u| u[:id] }).to eq([
      "c-#{@c1.id}-applied",
      "c-#{@c1.id}-created"
    ])
    expect(ActivityUpdates.updates_since.map {|u| u[:entity_type] }).to eq([
      "changeset",
      "changeset"
    ])
    expect(ActivityUpdates.updates_since.map {|u| u[:entity_action] }).to eq([
      "applied",
      "created",
    ])
  end

  it 'feeds imported' do
    Timecop.travel(5.minutes.ago) do
      @fvi1 = create(:feed_version_import, success: true)
    end
    expect(ActivityUpdates.updates_since[0][:id]).to eq "fvi-#{@fvi1.id}-created"
    expect(ActivityUpdates.updates_since[0][:entity_type]).to eq "feed"
    expect(ActivityUpdates.updates_since[0][:entity_id]).to eq Feed.first.onestop_id
    expect(ActivityUpdates.updates_since[0][:entity_action]).to eq 'imported'
    expect(ActivityUpdates.updates_since[0][:at_datetime]).to eq FeedVersionImport.first.created_at
  end

  it 'but not feed imports in progress' do
    Timecop.travel(1.minutes.ago) do
      @fvi1 = create(:feed_version_import, success: nil)
    end
    expect(ActivityUpdates.updates_since.map { |au| au[:entity_action]} ).not_to include('imported')
  end

  it 'feeds fetched' do
    Timecop.travel(10.minutes.ago) do
      @fv = create(:feed_version)
    end
    expect(ActivityUpdates.updates_since[0][:id]).to eq "fv-#{@fv.sha1}-created"
    expect(ActivityUpdates.updates_since[0][:entity_type]).to eq "feed"
    expect(ActivityUpdates.updates_since[0][:entity_id]).to eq Feed.first.onestop_id
    expect(ActivityUpdates.updates_since[0][:entity_action]).to eq 'fetched'
  end

  context 'feed_maintenance_issues' do
    it 'feeds maintenance extended' do
      issue_type = "feed_version_maintenance_extend"
      Timecop.travel(10.minutes.ago) do
        @fv = create(:feed_version)
        @issue = Issue.create!(issue_type: issue_type)
        @issue.entities_with_issues.create!(entity: @fv)
      end
      updates = ActivityUpdates.issues_created(1.day.ago)
      expect(updates.length).to eq(1)
      expect(updates.first[:id]).to eq("issue-#{@issue.id}-created")
      expect(updates.first[:at_datetime]).to be_within(1.second).of(@issue.created_at)
      expect(updates.first[:entity_type]).to eq('issue')
      expect(updates.first[:entity_id]).to eq(@issue.id)
      expect(updates.first[:entity_action]).to eq(issue_type)
    end

    it 'feeds maintenance imported' do
      issue_type = "feed_version_maintenance_import"
      Timecop.travel(10.minutes.ago) do
        @fv = create(:feed_version)
        @issue = Issue.create!(issue_type: issue_type)
        @issue.entities_with_issues.create!(entity: @fv)
      end
      updates = ActivityUpdates.issues_created(1.day.ago)
      expect(updates.length).to eq(1)
      expect(updates.first[:id]).to eq("issue-#{@issue.id}-created")
      expect(updates.first[:at_datetime]).to be_within(1.second).of(@issue.created_at)
      expect(updates.first[:entity_type]).to eq('issue')
      expect(updates.first[:entity_id]).to eq(@issue.id)
      expect(updates.first[:entity_action]).to eq(issue_type)
    end
  end

end
