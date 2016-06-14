describe Api::V1::IssuesController do
  before(:each) do
    load_feed(feed_version_name: :feed_version_example_issues, import_level: 2)
  end

  describe 'GET index' do

  end

  describe 'GET show' do
    it 'returns a 404 when not found' do
      get :show, id: 33
      expect(response.status).to eq 404
    end
  end
end
