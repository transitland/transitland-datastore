describe Api::V1::IssuesController do

  # TODO: loading this feed each test is slow
  before(:each) do
    allow(Figaro.env).to receive(:transitland_datastore_auth_token) { 'THISISANAPIKEY' }
    @request.env['HTTP_AUTHORIZATION'] = 'Token token=THISISANAPIKEY'
    load_feed(feed_version_name: :feed_version_example_issues, import_level: 1)
  end

  context 'GET index' do
    it 'returns all issues as json' do
      get :index
      expect_json_types({ issues: :array })
      expect_json({ issues: -> (issues) {
        expect(issues.length).to be > 0
      }})
    end

    it 'returns issues with correct issue_type' do
      get :index, issue_type: 'stop_rsp_distance_gap,route_color,fake'
      expect_json({ issues: -> (issues) {
        expect(issues.length).to be > 0
      }})
    end

    it 'returns empty with no correct issue_type' do
      get :index, issue_type: 'route_color,fake'
      expect_json({ issues: -> (issues) {
        expect(issues.length).to eq 0
      }})
    end

    it 'returns issues with feed' do
      changeset = create(:changeset)
      Issue.new(created_by_changeset: changeset, issue_type: 'stop_position_inaccurate').save!
      get :index, feed_onestop_id: 'f-9qs-example'
      expect_json({ issues: -> (issues) {
        expect(issues.length).to eq 8
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
    before(:each) do
      @issue1 = {
        "details": "This is a test issue",
        "issue_type": 'rsp_line_inaccurate',
        "entities_with_issues": [
          {
            "onestop_id": "s-9qt0rnrkjt-amargosavalleydemo",
            "entity_attribute": "geometry"
          },
          {
            "onestop_id": "r-9qt1-50-f8249d-e5d0eb",
            "entity_attribute": "geometry"
          }
        ]
      }
    end

    it 'creates an issue when no equivalent exists' do
      post :create, issue: @issue1
      expect(response.status).to eq 202
      expect(Issue.count).to eq 9 # was 8
      expect(EntityWithIssues.count).to eq 13 # was 11
    end

    it 'does not create issue when an equivalent one exists' do
      issue2 = {
        "details": "This is a test issue",
        "issue_type": 'stop_rsp_distance_gap',
        "entities_with_issues": [
          {
            "onestop_id": "s-9qscwx8n60-nyecountyairportdemo",
            "entity_attribute": "geometry"
          },
          {
            "onestop_id": "r-9qscy-30-a41e99-fcca25",
            "entity_attribute": "geometry"
          }
        ]
      }
      post :create, issue: issue2
      expect(response.status).to eq 409
      expect(Issue.count).to be > 0
    end

    it 'requires auth token to create issue' do
      @request.env['HTTP_AUTHORIZATION'] = nil
      post :create, issue: @issue1
      expect(response.status).to eq(401)
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

    it 'avoids deleting EntitiesWithIssues when param not supplied' do
      issue = {
        "details": "This is a test of updating"
      }
      post :update, id: 1, issue: issue
      expect(Issue.find(7).entities_with_issues.size).to eq 3
    end

    it 'creates specified EntitiesWithIssues and deletes existing EntitiesWithIssues' do
      issue = {
        "details": "This is a test of updating",
        entities_with_issues: [
          {
            "onestop_id": 's-9qscwx8n60-nyecountyairportdemo',
            "entity_attribute": 'geometry'
          }
        ]
      }
      post :update, id: 1, issue: issue
      expect(Issue.find(1).entities_with_issues.size).to eq 1
      expect(Issue.find(1).entities_with_issues[0].entity.onestop_id).to eq 's-9qscwx8n60-nyecountyairportdemo'
    end
  end

  context 'POST destroy' do
    it 'should delete issue' do
      post :destroy, id: 1
      expect(Issue.exists?(1)).to eq(false)
    end

    it 'should require auth token to delete issue' do
      @request.env['HTTP_AUTHORIZATION'] = nil
      issue = Issue.new(details: "This is a test issue", created_by_changeset_id: 1, issue_type: "stop_rsp_distance_gap")
      issue.save!
      issue.entities_with_issues.create(entity: Stop.find_by_onestop_id!('s-9qscwx8n60-nyecountyairportdemo'), entity_attribute: "geometry")
      post :destroy, id: issue.id
      expect(response.status).to eq(401)
    end
  end
end
