describe Api::V1::UsersController do
  before(:each) do
    allow(Figaro.env).to receive(:transitland_datastore_auth_token) { 'THISISANOTHERKEY' }
    @request.env['HTTP_AUTHORIZATION'] = 'Token token=THISISANOTHERKEY'
  end

  let(:user) { create(:user) }

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
        expect(users.length).to eq 2
      }})
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
