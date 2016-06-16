describe Api::V1::IssuesController do
  before(:each) do
    load_feed(feed_version_name: :feed_version_example_issues, import_level: 1)
  end

  context 'GET index' do
    it 'returns all issues as json' do
      get :index
      expect_json_types({ issues: :array })
      expect_json({ issues: -> (issues) {
        expect(issues.length).to eq 1
      }})
    end
  end

  context 'GET show' do
    it 'returns a 404 when not found' do
      get :show, id: 33
      expect(response.status).to eq 404
    end
  end

  context 'POST create' do
    it 'creates an issue when no equivalent exists' do
      issue = {
        "details": "This is a test issue",
        "issue_type": 'stop_rsp_distance_gap',
        "entities_with_issues": [
          {
            "onestop_id": "s-9qscwx8n60-nyecountyairportdemo",
            "entity_attribute": "geometry"
          },
          {
            "onestop_id": "r-9qscy-10-7beffb-b49819",
            "entity_attribute": "geometry"
          }
        ]
      }
      post :create, issue: issue
      expect(response.status).to eq 202
      expect(Issue.count).to eq 2
    end

    it 'does not create issue when an equivalent one exists' do
      issue = {
        "details": "This is a test issue",
        "issue_type": 'stop_rsp_distance_gap',
        "entities_with_issues": [
          {
            "onestop_id": "s-9qscwx8n60-nyecountyairportdemo",
            "entity_attribute": "geometry"
          },
          {
            "onestop_id": "r-9qscy-30-90db19-304219",
            "entity_attribute": "geometry"
          }
        ]
      }
      post :create, issue: issue
      expect(response.status).to eq 409
      expect(Issue.count).to eq 1
    end
  end

  context 'POST update' do
    it 'updates an existing issue' do
      issue = {
        "details": "This is a test of updating"
      }
      post :update, id: 1, issue: issue
      expect(Issue.find(1).details).to eq "This is a test of updating"
    end
  end

  context 'POST destroy' do
    it 'should delete issue' do
      post :destroy, id: 1
      expect(Issue.exists?(1)).to eq(false)
    end
  end
end
