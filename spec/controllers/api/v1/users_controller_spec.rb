describe Api::V1::UsersController do
  let(:user) { create(:user) }
  let(:auth_token) { JwtAuthToken.issue_token({user_id: user.id}) }

  before(:each) do
    @request.env['HTTP_AUTHORIZATION'] = "Bearer #{auth_token}"
  end

  context 'GET index' do
    it 'requires auth key to view' do
      @request.env['HTTP_AUTHORIZATION'] = nil
      get :index
      expect(response.status).to eq 401
    end

    it 'lists all users when auth key is provided' do
      create_list(:user, 2)
      get :index
      expect_json_types({ users: :array })
      expect_json({ users: -> (users) {
        expect(users.length).to eq 3 # because we create one for auth
      }})
    end

    it 'as CSV' do
      create_list(:user, 2)
      get :index, format: :csv
      parsed_csv = CSV.parse(response.body)
      expect(parsed_csv[0]).to eq ["Name", "Affiliation", "User Type", "Email"]
      expect(parsed_csv.length).to eq 4 # because we create one for auth
    end
  end

  describe 'POST create' do
    it 'can create a new user' do
      post :create, user: FactoryGirl.attributes_for(:user)
      expect(response.status).to eq 200
      expect(User.count).to eq 2 # because we already created one for auth
    end
  end

  describe 'POST destroy' do
    it 'can destroy a user' do
      post :destroy, id: user.id
      expect(response.status).to eq 204
      expect(User.count).to eq 0
    end
  end

  describe 'PUT update' do
    it 'can update an existing user' do
      initial_email = user.email
      put :update, id: user.id, user: { email: 'new@example.com' }
      expect(response.status).to eq 200
      expect(User.first.email).to eq 'new@example.com'
    end
  end

  describe 'GET show' do
    it 'returns a user' do
      get :show, id: user.id
      expect_json_types({
        email: :string,
        created_at: :date,
        updated_at: :date
      })
      expect_json({ email: -> (email) {
        expect(email).to eq user.email
      }})
    end

    it 'returns a 404 when not found' do
      get :show, id: 2
      expect(response.status).to eq 404
    end
  end
end
