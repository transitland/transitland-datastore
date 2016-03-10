describe ActivityUpdates do
  it 'lists changesets created' do
    user = create(:user)
    Timecop.freeze(Time.now - 3.minutes) do
      @c2 = create(:changeset, user: user)
    end
    Timecop.freeze(Time.now - 5.minutes) do
      @c1 = create(:changeset, user: user)
    end
    expect(ActivityUpdates.updates_since).to eq([
      {
        id: "c-#{@c1.id}-created",
        entity_type: 'changeset',
        entity_id: @c1.id,
        entity_action: 'created',
        by_user_id: User.first.id,
        note: @c1.notes,
        at_datetime: @c1.created_at
      },
      {
        id: "c-#{@c2.id}-created",
        entity_type: 'changeset',
        entity_id: @c2.id,
        entity_action: 'created',
        by_user_id: User.first.id,
        note: @c2.notes,
        at_datetime: @c2.created_at
      }
    ])
  end

  it 'lists changesets updated' do
    Timecop.travel(Time.now - 5.minutes) do
      create(:changeset)
    end
    Timecop.travel(Time.now - 3.minutes) do
      create(:changeset)
    end
    Changeset.first.update(notes: 'new note')
    # expect(ActivityUpdates.updates_since).to eq([
    #   {
    #     id: "c-#{Changeset.first.id}-updated",
    #     entity_type: 'changeset',
    #     entity_id: Changeset.first.id,
    #     entity_action: 'created',
    #     by_user_id: nil,
    #     note: Changeset.first.notes,
    #     at_datetime: Changeset.first.updated_at
    #   },
    #   {
    #     id: "c-#{Changeset.second.id}-created",
    #     entity_type: 'changeset',
    #     entity_id: Changeset.second.id,
    #     entity_action: 'created',
    #     by_user_id: nil,
    #     note: Changeset.second.notes,
    #     at_datetime: Changeset.second.created_at
    #   },
    #   {
    #     id: "c-#{Changeset.first.id}-created",
    #     entity_type: 'changeset',
    #     entity_id: Changeset.first.id,
    #     entity_action: 'created',
    #     by_user_id: nil,
    #     note: Changeset.first.notes,
    #     at_datetime: Changeset.first.created_at
    #   }
    # ])
    expect(ActivityUpdates.updates_since[0][:at_datetime].localtime).to be_within(1.second).of(Time.now)
    expect(ActivityUpdates.updates_since[1][:at_datetime].localtime).to be_within(1.second).of(Time.now - 3.minutes)
    expect(ActivityUpdates.updates_since[2][:at_datetime].localtime).to be_within(1.second).of(Time.now - 5.minutes)
  end
end