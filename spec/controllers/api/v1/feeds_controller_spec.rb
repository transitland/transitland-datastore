describe Api::V1::FeedsController do
  context 'GET index' do
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

    it 'filters by Onestop ID' do
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
  end

  context 'GET fetch_info' do
    pending 'a spec in the future'
  end
end
