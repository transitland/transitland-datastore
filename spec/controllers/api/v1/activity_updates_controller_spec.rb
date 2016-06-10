describe Api::V1::ActivityUpdatesController do
  context 'GET index' do
    before(:each) do
      Rails.cache.clear

      Timecop.travel(5.minutes.ago) do
        @c1 = create(:changeset)
        @f = create(:feed)
        @fv = create(:feed_version, feed: @f)
      end
      Timecop.travel(3.minutes.ago) do
        @c2 = create(:changeset)
        @fvi = create(:feed_version_import, feed_version: @fv, feed: @f, success: true)
      end
      @c1.update(notes: 'new note')
    end

    context 'as JSON' do
      it 'returns a list of recent updates' do
        get :index
        expect_json(activity_updates: -> (activity_updates) {
          expect(activity_updates.length).to eq 5
        })
      end

      it 'can filter by feed' do
        get :index, feed: @f.onestop_id
        expect_json(activity_updates: -> (activity_updates) {
          expect(activity_updates.length).to eq 2
        })
      end

      it 'can filter by multiple feeds' do
        fv2 = create(:feed_version)
        get :index, feed: "#{@f.onestop_id},#{fv2.feed.onestop_id}"
        expect_json(activity_updates: -> (activity_updates) {
          expect(activity_updates.length).to eq 3
        })
      end

      it 'can filter by changeset' do
        get :index, changeset: @c1.id
        expect_json(activity_updates: -> (activity_updates) {
          expect(activity_updates.length).to eq 2
        })
      end

      it 'can filter by multiple changesets' do
        get :index, changeset: "#{@c1.id},#{@c2.id}"
        expect_json(activity_updates: -> (activity_updates) {
          expect(activity_updates.length).to eq 3
        })
      end
    end

    context 'as RSS' do
      it 'returns a list of recent updates' do
        get :index, format: :rss
        expect(response.content_type).to eq 'application/rss+xml'
        expect(response).to be_ok
      end
    end
  end
end
