describe Api::V1::FeedVersionImportsController do
  context 'GET index' do
    it 'returns all FeedVersionImports when no parameters provided' do
      create_list(:feed_version_import, 2)
      get :index, total: true
      expect_json_types({ feed_version_imports: :array })
      expect_json({
        feed_version_imports: -> (feed_version_imports) {
          expect(feed_version_imports.length).to eq 2
        },
        meta: {
          total: 2
        }
      })
    end
  end
end
