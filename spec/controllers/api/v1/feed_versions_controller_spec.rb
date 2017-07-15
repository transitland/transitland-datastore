describe Api::V1::FeedVersionsController do
  context 'GET index' do
    it 'returns all FeedVersions when no parameters provided' do
      create_list(:feed_version, 2)
      get :index, total: true
      expect_json_types({ feed_versions: :array })
      expect_json({
        feed_versions: -> (feed_versions) {
          expect(feed_versions.length).to eq 2
        },
        meta: {
          total: 2
        }
      })
    end

    it 'calendar_coverage_begins_at_or_before' do
      fv1 = create(:feed_version, earliest_calendar_date: '2016-01-01', latest_calendar_date: '2017-01-01')
      fv2 = create(:feed_version, earliest_calendar_date: '2016-02-01', latest_calendar_date: '2017-02-01')
      get :index, calendar_coverage_begins_at_or_before: '2016-01-01'
      expect_json({feed_versions: -> (feed_versions) {
        expect(feed_versions.map { |fv| fv[:sha1]}).to match_array([fv1.sha1])
      }})
    end

    it 'calendar_coverage_begins_at_or_after' do
      fv1 = create(:feed_version, earliest_calendar_date: '2016-01-01', latest_calendar_date: '2017-01-01')
      fv2 = create(:feed_version, earliest_calendar_date: '2016-02-01', latest_calendar_date: '2017-02-01')
      get :index, calendar_coverage_begins_at_or_after: '2016-02-01'
      expect_json({feed_versions: -> (feed_versions) {
        expect(feed_versions.map { |fv| fv[:sha1]}).to match_array([fv2.sha1])
      }})
    end

    it 'calendar_coverage_includes' do
      fv1 = create(:feed_version, earliest_calendar_date: '2016-01-01', latest_calendar_date: '2017-01-01')
      fv2 = create(:feed_version, earliest_calendar_date: '2016-02-01', latest_calendar_date: '2017-02-01')
      get :index, calendar_coverage_includes: '2017-01-15'
      expect_json({feed_versions: -> (feed_versions) {
        expect(feed_versions.map { |fv| fv[:sha1]}).to match_array([fv2.sha1])
      }})
    end

    it 'filters by SHA1 hash' do
      create_list(:feed_version, 2)
      sha1 = FeedVersion.first.sha1
      get :index, sha1: sha1
      expect_json_types({ feed_versions: :array })
      expect_json({
        feed_versions: -> (feed_versions) {
          expect(feed_versions.length).to eq 1
          expect(feed_versions.first[:sha1]).to eq sha1
        }
      })
    end

    it 'filters by feed Onestop ID' do
      feed1 = create(:feed)
      feed2 = create(:feed)
      feed1_version1 = create(:feed_version, feed: feed1)
      feed2_version1 = create(:feed_version, feed: feed2)
      get :index, feed_onestop_id: feed2.onestop_id
      expect_json_types({ feed_versions: :array })
      expect_json({
        feed_versions: -> (feed_versions) {
          expect(feed_versions.length).to eq 1
          expect(feed_versions.first[:sha1]).to eq feed2_version1.sha1
        }
      })
    end
  end

  context 'POST create' do
    let(:user) { create(:user) }
    let(:auth_token) { JwtAuthToken.issue_token({user_id: user.id}) }
    let(:url) { 'http://example.com/example-create.zip' }
    let(:file) { Rails.root.join('spec/support/example_gtfs_archives/example.zip') }
    let(:sha1) { Digest::SHA1.file(file).hexdigest }
    let(:feed) { create(:feed_example) }
    before(:each) do
      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{auth_token}"
    end

    it 'creates a feed_version' do
      expect(feed.feed_versions.count).to eq(0)
      post :create, feed_version: {
        feed_onestop_id: feed.onestop_id,
        url: url,
        file: file
      }
      feed.reload
      expect(feed.feed_versions.count).to eq(1)
      expect(feed.feed_versions.first.url).to eq(url)
      expect(feed.feed_versions.first.sha1).to eq(sha1)
    end

    it 'enqueues GTFSValidationWorker' do
      expect {
        post :create, feed_version: {
          feed_onestop_id: feed.onestop_id,
          url: url,
          file: file
        }
      }.to change(GTFSValidationWorker.jobs, :size).by(1)
    end

    it 'enqueues GTFSStatisticsWorker' do
      expect {
        post :create, feed_version: {
          feed_onestop_id: feed.onestop_id,
          url: url,
          file: file
        }
      }.to change(GTFSStatisticsWorker.jobs, :size).by(1)
    end
  end

  context 'PUT update' do
    let(:user) { create(:user) }
    let(:auth_token) { JwtAuthToken.issue_token({user_id: user.id}) }
    before(:each) do
      # requires authentication
      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{auth_token}"

      @feed_version = create(:feed_version, import_level: 0)
    end

    it 'requires auth key to update' do
      @request.env['HTTP_AUTHORIZATION'] = nil
      put :update, id: @feed_version.sha1
      expect(response.status).to eq(401)
    end

    it 'allows import_level to be changed' do
      import_level = 5
      put :update, id: @feed_version.sha1, feed_version: {import_level: import_level}
      expect(response.status).to eq(200)
      expect_json(import_level: import_level)
      expect(@feed_version.reload.import_level).to eq(import_level)
    end

    it 'disallows editing other attributes' do
      sha1 = @feed_version.sha1
      put :update, id: @feed_version.sha1, feed_version: {sha1: 'asdf'}
      expect(@feed_version.reload.sha1).to eq(sha1)
    end
  end
end
