describe Api::V1::WebhooksController do
  before(:each) do
    allow(Figaro.env).to receive(:transitland_datastore_auth_token) { 'THISISANOTHERKEY' }
    @request.env['HTTP_AUTHORIZATION'] = 'Token token=THISISANOTHERKEY'
  end

  context 'POST feed_eater' do
    it 'should enqueue a new FeedEaterWorker' do
      expect {
        post :feed_eater
      }.to change(FeedEaterWorker.jobs, :size).by(1)
      expect_json({ code: 200, errors: [] })
    end

    it 'can take a single feed Onestop ID' do
      allow(FeedEaterWorker).to receive(:perform_async) { true }
      expect(FeedEaterWorker).to receive(:perform_async).with(['f-9q9-bayarearapidtransit'])
      post :feed_eater, feed_onestop_ids: 'f-9q9-bayarearapidtransit'
      expect_json({ code: 200, errors: [] })
    end

    it 'can take multiple feed Onestop IDs' do
      allow(FeedEaterWorker).to receive(:perform_async) { true }
      expect(FeedEaterWorker).to receive(:perform_async).with(['f-9q9-bayarearapidtransit', 'f-9q9-actransit'])
      post :feed_eater, feed_onestop_ids: 'f-9q9-bayarearapidtransit,f-9q9-actransit'
      expect_json({ code: 200, errors: [] })
    end
  end
end
