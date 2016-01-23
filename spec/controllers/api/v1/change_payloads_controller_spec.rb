describe Api::V1::ChangePayloadsController do
    before(:each) do
      allow(Figaro.env).to receive(:transitland_datastore_auth_token) { 'THISISANAPIKEY' }
      @request.env['HTTP_AUTHORIZATION'] = 'Token token=THISISANAPIKEY'
      @changeset = create(:changeset)
      @change_payload = create(:change_payload, changeset: @changeset)
    end

    # let(:changeset) { create(:changeset) }
    # let(:change_payload) { create(:change_payload, changeset: changeset) }

    context 'member' do
      it 'requires Changeset associated ChangePayload' do
        change_payload2 = create(:change_payload)
        get :show, changeset_id: @changeset.id, id: change_payload2.id
        expect(response.status).to eq(404)
      end

      it 'requires a valid ChangePayload' do
        get :show, changeset_id: @changeset.id, id: 1000
        expect(response.status).to eq(404)
      end
    end

    context 'GET index' do
      it 'returns all ChangePayloads' do
        get :index, changeset_id: @changeset.id
        expect_json(change_payloads: -> (change_payloads) {
            expect(change_payloads.size).to eq(1)
            expect(change_payloads.first[:id]).to eq(@change_payload.id)
        })
      end

      it 'paginates ChangePayloads' do
        change_payload2 = create(:change_payload, changeset: @changeset)
        get :index, changeset_id: @changeset.id, per_page: 1, offset: 1
        expect_json(change_payloads: -> (change_payloads) {
            expect(change_payloads.size).to eq(1)
            expect(change_payloads.first[:id]).to eq(change_payload2.id)
        })
      end
    end

    context 'GET show' do
      it 'shows a ChangePayload' do
        get :show, changeset_id: @changeset.id, id: @change_payload.id
        expect_json('change_payload', {
          id: @change_payload.id,
          changeset_id: @changeset.id
        })
      end
    end

    context 'POST create' do
      it 'creates a ChangePayload' do
        change = FactoryGirl.attributes_for(:change_payload)
        post :create, changeset_id: @changeset.id, change_payload: change
        expect_json('change_payload', payload: -> (payload) {
          expect(payload).to eq(change[:payload])
        })
      end

      it 'adds ChangePayload to Changeset' do
        change = FactoryGirl.attributes_for(:change_payload)
        expect(@changeset.change_payloads.size).to eq(1)
        post :create, changeset_id: @changeset.id, change_payload: change
        expect_json('change_payload', {
          changeset_id: @changeset.id
        })
        expect(@changeset.change_payloads.size).to eq(2)
      end

      it 'cannot add ChangePayload to applied Changeset' do
        @changeset.apply!
        change = FactoryGirl.attributes_for(:change_payload)
        post :create, changeset_id: @changeset.id, change_payload: change
        expect(response.status).to eq(400)
      end
    end

    context 'POST update' do
      it 'updates a ChangePayload' do
        change = FactoryGirl.attributes_for(:change_payload)
        post :update, changeset_id: @changeset.id, id: @change_payload.id, change_payload: change
        expect_json('change_payload', payload: -> (payload) {
          expect(payload).to eq(change[:payload])
        })
      end

      it 'cannot update ChangePayload to applied Changeset' do
        # Not normally be possible as ChangePayloads destroyed after apply
        @changeset.apply!
        @change_payload = create(:change_payload, changeset: @changeset)
        change = FactoryGirl.attributes_for(:change_payload)
        post :update, changeset_id: @changeset.id, id: @change_payload.id, change_payload: change
        expect(response.status).to eq(400)
      end
    end

    context 'POST destroy' do
      it 'deletes a ChangePayload' do
        post :destroy, changeset_id: @changeset.id, id: @change_payload.id
        expect(ChangePayload.exists?(@change_payload.id)).to be(false)
        expect(@changeset.change_payloads.size).to eq(0)
      end

      it 'cannot delete a ChangePayload to applied Changeset' do
        # Not normally be possible as ChangePayloads destroyed after apply
        @changeset.apply!
        @change_payload = create(:change_payload, changeset: @changeset)
        post :destroy, changeset_id: @changeset.id, id: @change_payload.id
        expect(response.status).to eq(400)
      end

      it 'requires auth key to delete ChangePayload' do
        @request.env['HTTP_AUTHORIZATION'] = nil
        post :destroy, changeset_id: @changeset.id, id: @change_payload.id
        expect(response.status).to eq(401)
      end
    end
end
