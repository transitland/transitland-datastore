describe Api::V1::WebhooksController do
  before(:each) do
    allow(Figaro.env).to receive(:api_auth_tokens) { 'THISISANAPIKEY,THISISANOTHERKEY' }
    @request.env['HTTP_AUTHORIZATION'] = 'Token token=THISISANOTHERKEY'
  end

  context 'POST feed_eater' do
    it 'should enqueue a new FeedEaterWorker' do
      expect {
        post :feed_eater
      }.to change(FeedEaterWorker.jobs, :size).by(1)
      expect_json({ code: 200, errors: [] })
    end
  end
end
