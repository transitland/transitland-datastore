describe ActivityUpdates do
  it 'lists changesets created' do
    user = create(:user)
    Timecop.freeze(3.minutes.ago) do
      @c2 = create(:changeset, user: user)
    end
    Timecop.freeze(5.minutes.ago) do
      @c1 = create(:changeset, user: user)
    end
    expect(ActivityUpdates.updates_since).to eq([
      {
        id: "c-#{@c2.id}-created",
        entity_type: 'changeset',
        entity_id: @c2.id,
        entity_action: 'created',
        by_user_id: User.first.id,
        note: @c2.notes,
        at_datetime: @c2.created_at
      },
      {
        id: "c-#{@c1.id}-created",
        entity_type: 'changeset',
        entity_id: @c1.id,
        entity_action: 'created',
        by_user_id: User.first.id,
        note: @c1.notes,
        at_datetime: @c1.created_at
      }
    ])
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
      @fvi1 = create(:feed_version_import)
    end
    expect(ActivityUpdates.updates_since[0][:id]).to eq "fvi-#{@fvi1.id}-created"
    expect(ActivityUpdates.updates_since[0][:entity_type]).to eq "feed"
    expect(ActivityUpdates.updates_since[0][:entity_id]).to eq Feed.first.onestop_id
    expect(ActivityUpdates.updates_since[0][:entity_action]).to eq 'imported'
    expect(ActivityUpdates.updates_since[0][:at_datetime]).to eq FeedVersionImport.first.created_at
  end

  it 'feeds imported' do
    Timecop.travel(10.minutes.ago) do
      @fv = create(:feed_version)
    end
    expect(ActivityUpdates.updates_since[0][:id]).to eq "fv-#{@fv.sha1}-created"
    expect(ActivityUpdates.updates_since[0][:entity_type]).to eq "feed"
    expect(ActivityUpdates.updates_since[0][:entity_id]).to eq Feed.first.onestop_id
    expect(ActivityUpdates.updates_since[0][:entity_action]).to eq 'fetched'
  end
end
