describe Api::V1::FeedsController do
  context 'GET index' do
    context 'as JSON' do
      it 'returns all Feeds when no parameters provided' do
        create_list(:feed, 2)
        get :index, total: true
        expect_json_types({ feeds: :array })
        expect_json({
          feeds: -> (feeds) {
            expect(feeds.length).to eq 2
          },
          meta: {
            total: 2
          }
        })
      end

      it 'query: onestop_id' do
        create_list(:feed, 3)
        onestop_id = Feed.second.onestop_id
        get :index, onestop_id: onestop_id
        expect_json_types({ feeds: :array })
        expect_json({
          feeds: -> (feeds) {
            expect(feeds.first[:onestop_id]).to eq onestop_id
          }
        })
      end

      it 'query: active_feed_version_import_level' do
        fv = create(:feed_version, import_level: 4)
        feed = fv.feed
        feed.update!(active_feed_version: fv)
        get :index, active_feed_version_import_level: 4
        expect_json({
          feeds: -> (feeds) {
            expect(feeds.first[:onestop_id]).to eq feed.onestop_id
          }
        })
      end

      it 'query: last_imported_since' do
        feeds = create_list(:feed, 3)
        past = DateTime.parse('2015-01-01 01:02:03')
        now = DateTime.parse('2016-01-01 00:00:00')
        future = DateTime.parse('2017-01-01')
        feed = feeds.last
        feed.update!(last_imported_at: now)
        feed_version = create(:feed_version, feed: feed)
        feed_version.feed_version_imports.create!
        get :index, last_imported_since: past
        expect_json({feeds: -> (feeds) {expect(feeds.size).to eq(1)}})
        get :index, last_imported_since: now
        expect_json({feeds: -> (feeds) {expect(feeds.size).to eq(1)}})
        get :index, last_imported_since: future
        expect_json({feeds: -> (feeds) {expect(feeds.size).to eq(0)}})
      end

      it 'query: latest_fetch_exception' do
        feeds = create_list(:feed, 3)
        feed = feeds.first
        Issue.create!(issue_type: 'feed_fetch_invalid_source').entities_with_issues.create!(entity: feed, entity_attribute: 'url')
        get :index
        expect_json({feeds: -> (feeds) {expect(feeds.size).to eq(3)}})
        get :index, latest_fetch_exception: 'true'
        expect_json({feeds: -> (feeds) {expect(feeds.size).to eq(1)}})
        get :index, latest_fetch_exception: 'false'
        expect_json({feeds: -> (feeds) {expect(feeds.size).to eq(2)}})
      end

      it 'query: where_latest_feed_version_import_status' do
        fvs = create_list(:feed_version, 3)
        fvs[0].feed_version_imports.create!(success: true)
        fvs[1].feed_version_imports.create!(success: false)
        fvs[2].feed_version_imports.create!(success: nil)
        get :index, latest_feed_version_import_status: 'true'
        expect_json({feeds: -> (feeds) {
          expect(feeds.length).to eq(1)
          expect(feeds.first[:onestop_id]).to eq(fvs[0].feed.onestop_id)
        }})
        get :index, latest_feed_version_import_status: 'false'
        expect_json({feeds: -> (feeds) {
          expect(feeds.length).to eq(1)
          expect(feeds.first[:onestop_id]).to eq(fvs[1].feed.onestop_id)
        }})
        get :index, latest_feed_version_import_status: 'null'
        expect_json({feeds: -> (feeds) {
          expect(feeds.length).to eq(1)
          expect(feeds.first[:onestop_id]).to eq(fvs[2].feed.onestop_id)
        }})
      end

      it 'query: embed_issues' do
        feeds = create_list(:feed, 3)
        feed = feeds.first
        Issue.create!(issue_type: 'feed_fetch_invalid_source').entities_with_issues.create!(entity: feed, entity_attribute: 'url')

        get :index, embed_issues: 'true'
        expect_json({feeds: -> (feeds) {
          expect(feeds.first[:issues].size).to eq 1
        }})

        get :index, embed_issues: 'false'
        expect_json({feeds: -> (feeds) {
          expect(feeds.first[:issues]).to be_nil
        }})
      end

      it 'query: by one source URL' do
        feeds = create_list(:feed, 3)
        feed_to_find = feeds.second
        get :index, url: feed_to_find.url
        expect_json({feeds: -> (feeds) {
          expect(feeds.size).to eq 1
          expect(feeds.first[:onestop_id]).to eq feed_to_find.onestop_id
        }})
      end

      it 'query: by two source URLs' do
        feeds = create_list(:feed, 3)
        feeds_to_find = [feeds.second, feeds.third]
        get :index, url: [feeds_to_find.first.url, feeds_to_find.second.url]
        expect_json({feeds: -> (feeds) {
          expect(feeds.size).to eq 2
        }})
      end
    end

    context 'as GeoJSON' do
      it 'should return GeoJSON for all feeds' do
        create_list(:feed, 2, geometry: {
          type: 'Polygon',
          coordinates: [
            [
              [-71.04819, 42.254056],
              [-70.9016389,42.254056],
              [-70.9016389,42.359837],
              [-71.04819,42.359837],
              [-71.04819,42.254056]
            ]
          ]
        })

        get :index, format: :geojson
        expect_json({
          type: 'FeatureCollection',
          features: -> (features) {
            expect(features.map {|f| f[:properties][:onestop_id] }).to match_array(Feed.pluck(:onestop_id))
          }
        })
      end
    end
  end

  context 'GET fetch_info' do
    pending 'a spec in the future'
  end

  context 'GET download_latest_feed_version' do
    before(:each) do
      @feed_that_allows_download = create(:feed, license_redistribute: 'unknown')
      @feed_that_disallows_download = create(:feed, license_redistribute: 'no')

      [@feed_that_allows_download, @feed_that_disallows_download].each do |feed|
        [2, 1].each do |i|
          fv = create(
            :feed_version,
            feed: feed,
            fetched_at: (DateTime.now - i.months)
          )
        end
      end

      allow_any_instance_of(FeedVersion).to receive_message_chain(:file, :url) { 'https://s3.aws.whatever/file.zip' }
    end

    it 'should redirect to latest file on S3 when license allows' do
      get :download_latest_feed_version, id: @feed_that_allows_download.onestop_id
      expect(response).to redirect_to('https://s3.aws.whatever/file.zip')
    end

    it 'should return a 404 when license disallows download' do
      get :download_latest_feed_version, id: @feed_that_disallows_download.onestop_id
      expect(response.status).to eq(404)
    end

  end
end
