describe ChangesetApplyWorker do

  before(:each) do
    payload = {
      changes: [
        {
          action: "createUpdate",
          stop: {
            onestopId:  's-9q9-test',
            name: '1st Ave. & Holloway St.',
            timezone: 'America/Los_Angeles',
            geometry: { type: 'Point', coordinates: [10.195312, 43.755225] }                          
          }
        }
      ]
    }
    @changeset = create(:changeset, payload: payload)
    @cachekey = "changesets/#{@changeset.id}/apply_async"
    Rails.cache.delete(@cachekey)
  end

  after(:each) do
    Rails.cache.delete(@cachekey)
  end

  it 'applies a changeset' do
    Sidekiq::Testing.inline! do
      ChangesetApplyWorker.perform_async(@changeset.id, @cachekey)
    end
    expect(@changeset.reload.applied).to eq(true)
  end

  it 'writes status' do
    Sidekiq::Testing.inline! do
      ChangesetApplyWorker.perform_async(@changeset.id, @cachekey)
    end
    cachedata = Rails.cache.fetch(@cachekey)
    expect(cachedata[:status]).to eq('complete')
  end

  it 'returns errors' do
    # missing timezone
    payload = {changes: [{action: 'createUpdate', stop: {onestopId: 's-9q9-test'}}]}
    @changeset.change_payloads.first.update(payload: payload)
    Sidekiq::Testing.inline! do
      ChangesetApplyWorker.perform_async(@changeset.id, @cachekey)
    end
    cachedata = Rails.cache.fetch(@cachekey)
    expect(cachedata[:status]).to eq('error')
    expect(cachedata[:errors].size).to eq(1)
    expect(cachedata[:errors].first[:exception]).to eq('ChangesetError')
  end

end
