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
end
