describe Api::V1::FeedVersionsController do
  before(:each) do
    allow(Figaro.env).to receive(:transitland_datastore_auth_token) { 'THISISANAPIKEY' }
    @request.env['HTTP_AUTHORIZATION'] = 'Token token=THISISANAPIKEY'
    @feed_version = create(:feed_version, import_level: 0)
  end

  context 'POST update' do
    it 'requires auth key to update' do
      @request.env['HTTP_AUTHORIZATION'] = nil
      post :update, feed_id: @feed_version.feed.onestop_id, id: @feed_version.sha1, feed_version: {}
      expect(response.status).to eq(401)
    end

    it 'allows import_level to be changed' do
      import_level = 5
      post :update, feed_id: @feed_version.feed.onestop_id, id: @feed_version.sha1, feed_version: {import_level: import_level}
      expect(response.status).to eq(200)
      expect_json(import_level: import_level)
      expect(@feed_version.reload.import_level).to eq(import_level)
    end

    it 'disallows editing other attributes' do
      sha1 = @feed_version.sha1
      post :update, feed_id: @feed_version.feed.onestop_id, id: @feed_version.sha1, feed_version: {sha1: 'asdf'}
      expect(@feed_version.reload.sha1).to eq(sha1)
    end
  end
end
