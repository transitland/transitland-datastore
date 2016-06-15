describe Api::V1::IssuesController do
  before(:each) do
    load_feed(feed_version_name: :feed_version_example_issues, import_level: 2)
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

    end

    it 'does not create issue when an equivalent one exists' do

    end
  end

  context 'issue resolution' do
    it 'resolves issue with issues_resolved changeset' do
      #post :create, changeset: FactoryGirl.attributes_for(:issue_resolving_changeset)
    end
  end
end
