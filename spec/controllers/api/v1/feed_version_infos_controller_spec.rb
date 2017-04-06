describe Api::V1::FeedVersionInfosController do
  context 'GET index' do
    it 'returns all FeedVersionInfos when no parameters provided' do
      feed_version_info = create_list(:feed_version_info, 2)
      get :index, total: true
      expect_json_types({ feed_version_infos: :array })
      expect_json({
        feed_version_infos: -> (feed_version_infos) {
          expect(feed_version_infos.length).to eq 2
        },
        meta: {
          total: 2
        }
      })
    end
  end
end
