describe Api::V1::WebhooksController do
  let(:user) { create(:user) }
  let(:auth_token) { JwtAuthToken.issue_token({user_id: user.id}) }

  before(:each) do
    @request.env['HTTP_AUTHORIZATION'] = "Bearer #{auth_token}"
  end

  context 'POST feed_fetcher' do
    it 'should enqueue a new FeedFetcher for every feed' do
      create_list(:feed, 4)
      expect {
        post :feed_fetcher
      }.to change(FeedFetcherWorker.jobs, :size).by(4)
      expect_json({ code: 200, errors: [] })
    end

    it 'should be able to enqueue just one FeedFetcher' do
      create_list(:feed, 4)
      Sidekiq::Testing.fake! do
        expect {
          post :feed_fetcher, feed_onestop_id: Feed.first.onestop_id
        }.to change(FeedFetcherWorker.jobs, :size).by(1)
      end
      expect_json({ code: 200, errors: [] })
    end
  end

  context 'POST feed_eater' do
    it 'returns a 404 if feed not found' do
      post :feed_eater, feed_onestop_id: 'f-9q9-caltrain', feed_version_sha1: 'ab1e6ac73943082803f110df4b0fdd63a1d6b9f7'
      expect(response.status).to eq 404
    end

    it 'should enqueue a new FeedEaterWorker' do
      create(:feed_version_caltrain)
      expect {
        post :feed_eater, feed_onestop_id: 'f-9q9-caltrain', feed_version_sha1: 'ab1e6ac73943082803f110df4b0fdd63a1d6b9f7'
      }.to change(FeedEaterWorker.jobs, :size).by(1)
      expect_json({ code: 200, errors: [] })
    end

    it 'can specify an import level' do
      create(:feed_version_caltrain)
      allow(FeedEaterWorker).to receive(:perform_async) { true }
      expect(FeedEaterWorker).to receive(:perform_async).with(
        'f-9q9-caltrain',
        'ab1e6ac73943082803f110df4b0fdd63a1d6b9f7',
        2
      )
      post :feed_eater,
           feed_onestop_id: 'f-9q9-caltrain',
           feed_version_sha1: 'ab1e6ac73943082803f110df4b0fdd63a1d6b9f7',
           import_level: 2
      expect_json({ code: 200, errors: [] })
    end

    # TODO: fix
    # it 'if no sha1 hash given, uses the most recent FeedVersion' do
    #   fv1 = create(:feed_version_caltrain)
    #   fv2 = create(:feed_version_bart, feed: Feed.find_by(onestop_id: 'f-9q9-caltrain'))
    #   allow(FeedEaterWorker).to receive(:perform_async) { true }
    #   expect(FeedEaterWorker).to receive(:perform_async).with(
    #     'f-9q9-caltrain',
    #     fv2.sha1,
    #     2
    #   )
    #   post :feed_eater,
    #        feed_onestop_id: 'f-9q9-caltrain',
    #        import_level: 2
    #   expect_json({ code: 200, errors: [] })
    # end
  end
end
