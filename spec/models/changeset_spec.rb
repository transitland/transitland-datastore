# == Schema Information
#
# Table name: changesets
#
#  id              :integer          not null, primary key
#  notes           :text
#  applied         :boolean
#  applied_at      :datetime
#  created_at      :datetime
#  updated_at      :datetime
#  user_id         :integer
#  feed_id         :integer
#  feed_version_id :integer
#
# Indexes
#
#  index_changesets_on_feed_id          (feed_id)
#  index_changesets_on_feed_version_id  (feed_version_id)
#  index_changesets_on_user_id          (user_id)
#

describe Changeset do
  context 'creation' do
    it 'is possible' do
      changeset = create(:changeset)
      expect(Changeset.exists?(changeset.id)).to be true
    end

    it 'is possible with an initial payload (compat)' do
      payload = {
        changes: [
          {
            action: "createUpdate",
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              name: '1st Ave. & Holloway St.'
            }
          }
        ]
      }
      changeset = build(:changeset, payload: payload)
      expect(changeset.change_payloads.count).equal?(1)
    end

    context 'creation e-mail' do
      it 'sent to normal user' do
        allow(Figaro.env).to receive(:send_changeset_emails_to_users) { 'true' }
        user = create(:user)
        changeset = create(:changeset, user: user)
        expect(ChangesetMailer.instance_method :creation).to be_delayed(changeset.id)
      end

      it 'not sent to admin user' do
        allow(Figaro.env).to receive(:send_changeset_emails_to_users) { 'false' }
        user = create(:user, admin: true)
        changeset = create(:changeset, user: user)
        expect(ChangesetMailer.instance_method :creation).to_not be_delayed(changeset.id)
      end

      it 'not sent when disabled' do
        allow(Figaro.env).to receive(:send_changeset_emails_to_users) { 'false' }
        user = create(:user)
        changeset = create(:changeset, user: user)
        expect(ChangesetMailer.instance_method :creation).to_not be_delayed(changeset.id)
      end
    end
  end

  it 'sorts payloads by created_at' do
    changeset = create(:changeset)
    10.times {
      create(:change_payload, changeset: changeset)
    }
    # Manually set created_at on the last payload to be earlier
    last_change = changeset.change_payloads.last
    last_change.created_at = "1970-01-01 00:00:00"
    last_change.save!
    # Compare association order vs manual sorted order
    changes_order = changeset.change_payloads.map(&:id)
    changes_expect = Changeset.last.change_payloads.sort_by {|x|x.created_at}.map(&:id)
    changes_order.zip(changes_expect).each {|a,b| assert a == b}
  end

  context 'can be applied' do
    before(:each) do
      @changeset1 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              name: '1st Ave. & Holloway Street'
            }
          }
        ]
      })
      @changeset2 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              name: '1st Ave. & Holloway St.'
            }
          }
        ]
      })
      @changeset2_bad = create(:changeset, payload: {
        changes: [
          {
            action: 'destroy',
            stop: {
              onestopId: 's-9q8yt4b-1Av',
            }
          }
        ]
      })
      @changeset3 = create(:changeset, payload: {
        changes: [
          {
            action: 'destroy',
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS'
            }
          }
        ]
      })
    end

    it 'trial_succeeds?' do
      @changeset1.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').name).to eq '1st Ave. & Holloway Street'
      expect(@changeset2.applied).to eq false
      expect(@changeset2.trial_succeeds?).to eq true
      expect(@changeset2.reload.applied).to eq false
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').name).to eq '1st Ave. & Holloway Street'
      expect(@changeset2_bad.trial_succeeds?).to eq false
      @changeset2.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').name).to eq '1st Ave. & Holloway St.'
    end

    it 'and will set applied and applied_at values' do
      expect(@changeset1.applied).to eq false
      expect(@changeset1.applied_at).to be_blank
      @changeset1.apply!
      expect(@changeset1.applied).to eq true
      expect(@changeset1.applied_at).to be_within(1.minute).of(Time.now)
    end

    it 'once but not twice' do
      @changeset1.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').name).to eq '1st Ave. & Holloway Street'
      expect {
        @changeset1.apply!
      }.to raise_error(Changeset::Error)
    end

    it 'to update an existing entity' do
      @changeset1.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').name).to eq '1st Ave. & Holloway Street'
      @changeset2.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').name).to eq '1st Ave. & Holloway St.'
    end

    it 'to delete an existing entity' do
      @changeset1.apply!
      expect(Stop.count).to eq 1
      @changeset2.apply!
      expect(Stop.count).to eq 1
      expect(OldStop.count).to eq 1
      @changeset3.apply!
      expect(Stop.count).to eq 0
      expect(OldStop.count).to eq 2
      expect(Stop.find_by_onestop_id('s-9q8yt4b-1AvHoS')).to be_nil
    end

    it 'to create and remove a relationship' do
      @changeset1.apply!
      @changeset2.apply!
      changeset3 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            operator: {
              onestopId: 'o-9q8y-SFMTA',
              name: 'SFMTA',
              serves: ['s-9q8yt4b-1AvHoS']
            },
          }
        ]
      })
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').operators.count).to eq 0
      changeset3.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').operators).to include Operator.find_by_onestop_id!('o-9q8y-SFMTA')

      changeset4 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              notServedBy: ['o-9q8y-SFMTA']
            },
          }
        ]
      })
      changeset4.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').operators.count).to eq 0
      expect(OldOperatorServingStop.count).to eq 1
      expect(OldOperatorServingStop.first.operator).to eq Operator.find_by_onestop_id!('o-9q8y-SFMTA')
      expect(OldOperatorServingStop.first.stop).to eq Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS')
    end

    context 'application e-mail' do
      it 'sent to normal user' do
        @changeset1.user = create(:user)
        @changeset1.apply!
        expect(ChangesetMailer.instance_method :application).to be_delayed(@changeset1.id)
      end

      it 'not sent to admin user' do
        @changeset1.user = create(:user, admin: true)
        @changeset1.apply!
        expect(ChangesetMailer.instance_method :application).to_not be_delayed(@changeset1.id)
      end

      it 'not sent when disabled' do
        allow(Figaro.env).to receive(:send_changeset_emails_to_users) { 'false' }
        @changeset1.user = create(:user)
        @changeset1.apply!
        expect(ChangesetMailer.instance_method :application).to_not be_delayed(@changeset1.id)
      end
    end
  end

  context 'revert' do
    pending 'write some specs'
  end

  context '#destroy_all_change_payloads' do
    it 'destroys all ChangePayloads' do
      changeset = create(:changeset_with_payload)
      payload_ids = changeset.change_payload_ids
      expect(payload_ids.length).to eq 1
      changeset.destroy_all_change_payloads
      payload_ids.each do |i|
        expect(ChangePayload.find_by(id: i)).to be_nil
      end
    end
  end

  it 'will conflate stops with OSM after the DB transaction is complete' do
    allow(Figaro.env).to receive(:auto_conflate_stops_with_osm) { 'true' }
    changeset = create(:changeset, payload: {
      changes: [
        {
          action: 'createUpdate',
          stop: {
            onestopId: 's-9q8yt4b-1AvHoS',
            name: '1st Ave. & Holloway Street',
          }
        }
      ]
    })
    allow(ConflateStopsWithOsmWorker).to receive(:perform_async) { true }
    # WARNING: we're expecting certain a ID in the database. This might
    # not be the case if the test suite is run in parallel.
    expect(ConflateStopsWithOsmWorker).to receive(:perform_async).with([1])
    changeset.apply!
  end
end
