describe Api::V1::ChangesetsController do
  before(:each) do
    allow(Figaro.env).to receive(:transitland_datastore_auth_token) { 'THISISANAPIKEY' }
    @request.env['HTTP_AUTHORIZATION'] = 'Token token=THISISANAPIKEY'
  end

  context 'GET index' do
    it 'returns all stops when no parameters provided' do
      create_list(:changeset, 2)
      get :index
      expect_json_types({ changesets: :array }) # TODO: remove root node?
      expect_json({ changesets: -> (changesets) {
        expect(changesets.length).to eq 2
      }})
    end
  end

  context 'GET show' do
    it 'returns a changeset when its ID is given' do
      create_list(:changeset, 2)
      get :show, id: Changeset.last.id
      expect_json({
        id: Changeset.last.id,
        applied: false,
        applied_at: nil
      })
    end

    it 'returns ChangePayloads IDs' do
      create_list(:changeset_with_payload, 2)
      changeset = Changeset.last
      get :show, id: changeset.id
      expect_json({
        id: changeset.id,
        change_payloads: changeset.change_payload_ids,
        applied: false,
        applied_at: nil
      })
    end
  end

  context 'POST create' do
    it 'should be able to create a Changeset with an empty payload' do
      post :create, changeset: FactoryGirl.attributes_for(:changeset)
      expect(response.status).to eq 200
      expect(Changeset.count).to eq 1
      expect(ChangePayload.count).to eq 0
    end

    it 'should be able to create a Changeset with a valid payload' do
      post :create, changeset: FactoryGirl.attributes_for(:changeset_with_payload)
      expect(response.status).to eq 200
      expect(Changeset.count).to eq 1
      expect(ChangePayload.count).to eq 1
    end

    it 'should fail to create a Changeset with an invalid payload' do
      post :create, changeset: {
        changes: []
      }
      expect(response.status).to eq 400
      expect(Changeset.count).to eq 0
    end

    it 'should allow Changeset creation without API Key' do
      @request.env['HTTP_AUTHORIZATION'] = nil
      attrs = FactoryGirl.attributes_for(:changeset_with_payload)
      post :create, changeset: attrs
      expect(response.status).to eq 200
    end

    it 'should be able to create a Changeset with a new author (User)' do
      post :create, changeset: FactoryGirl.attributes_for(:changeset).merge({ author_email: 'dummy@example.com' })
      expect(response.status).to eq 200
      expect(Changeset.count).to eq 1
      expect(User.count).to eq 1
      expect(Changeset.first.author).to eq User.first
      expect(User.first.changesets).to match_array(Changeset.all)
    end

    it 'should be able to create a Changeset with an existing author (User)' do
      user = create(:user)
      post :create, changeset: FactoryGirl.attributes_for(:changeset).merge({ author_email: user.email })
      expect(response.status).to eq 200
      expect(Changeset.count).to eq 1
      expect(User.count).to eq 1
      expect(Changeset.first.author).to eq user
    end
  end

  context 'POST destroy' do
    it 'should delete Changeset' do
      changeset = create(:changeset)
      post :destroy, id: changeset.id
      expect(Changeset.exists?(changeset.id)).to eq(false)
    end

    it 'should delete Changeset and dependent ChangePayloads' do
      changeset = create(:changeset_with_payload)
      change_payload = changeset.change_payloads.first
      expect(Changeset.exists?(changeset.id)).to eq(true)
      expect(ChangePayload.exists?(change_payload.id)).to eq(true)
      post :destroy, id: changeset.id
      expect(Changeset.exists?(changeset.id)).to eq(false)
      expect(ChangePayload.exists?(change_payload.id)).to eq(false)
    end

    it 'should require auth token to delete Changeset' do
      @request.env['HTTP_AUTHORIZATION'] = nil
      changeset = create(:changeset)
      post :destroy, id: changeset.id
      expect(response.status).to eq(401)
    end

  end

  context 'POST update' do
    it "should be able to update a Changeset that hasn't yet been applied" do
      changeset = create(:changeset)
      post :update, id: changeset.id, changeset: {
        notes: 'this is the NEW note'
      }
      expect(changeset.reload.notes).to eq 'this is the NEW note'
    end
  end

  context 'POST check' do
    it 'should be able to identify a Changeset that will apply cleanly' do
      changeset = create(:changeset)
      post :check, id: changeset.id
      expect_json({ trialSucceeds: true })
      expect(changeset.applied).to eq false
    end

    it 'should be able to identify a Changeset that will NOT apply cleanly' do
      changeset = create(:changeset, payload: {
        changes: [
          action: 'destroy',
          stop: {
            onestopId: 's-5b2-Fake'
          }
        ]
      })
      post :check, id: changeset.id
      expect_json({ trialSucceeds: false })
      expect(changeset.applied).to eq false
    end
  end

  context 'POST apply' do
    it 'should be able to apply a clean Changeset' do
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              name: '1st Ave. & Holloway Street',
              operatorsServingStop: [
                {
                  operatorOnestopId: 'o-9q8y-SFMTA'
                }
              ]
            }
          }
        ]
      })
      expect(Stop.count).to eq 0
      post :apply, id: changeset
      expect(OnestopId.find!('s-9q8yt4b-1AvHoS').name).to eq '1st Ave. & Holloway Street'
      expect_json({ applied: true })
    end

    it 'should fail when API auth token is not provided' do
      @request.env['HTTP_AUTHORIZATION'] = nil
      changeset = create(:changeset)
      post :apply, id: changeset.id
      expect(response.status).to eq 401
    end

    it "will fail gracefully when a Changeset doesn't apply" do
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'destroy',
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS'
            }
          }
        ]
      })
      post :apply, id: changeset.id
      expect(response.status).to eq 400
    end
  end

  context 'POST revert' do
    pending 'write the revert functionality'
  end
end
