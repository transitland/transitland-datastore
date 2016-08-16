describe ChangesetApplyWorker do
  it 'applies a changeset' do
    onestop_id = 's-9q9-test'
    payload = {
      changes: [
        {
          action: "createUpdate",
          stop: {
            onestopId: onestop_id,
            name: '1st Ave. & Holloway St.',
            timezone: 'America/Los_Angeles'
          }
        }
      ]
    }
    changeset = create(:changeset, payload: payload)
    Sidekiq::Testing.inline! do
      ChangesetApplyWorker.perform_async(changeset.id, 'test')
    end
    expect(changeset.reload.applied).to eq(true)
    expect(Stop.find_by_onestop_id(onestop_id)).to be_truthy
  end
end
