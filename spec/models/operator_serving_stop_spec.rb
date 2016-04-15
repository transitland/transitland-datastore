# == Schema Information
#
# Table name: current_operators_serving_stop
#
#  id                                 :integer          not null, primary key
#  stop_id                            :integer          not null
#  operator_id                        :integer          not null
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#
# Indexes
#
#  #c_operators_serving_stop_cu_in_changeset_id_index               (created_or_updated_in_changeset_id)
#  index_current_operators_serving_stop_on_operator_id              (operator_id)
#  index_current_operators_serving_stop_on_stop_id                  (stop_id)
#  index_current_operators_serving_stop_on_stop_id_and_operator_id  (stop_id,operator_id) UNIQUE
#

describe OperatorServingStop do
  it 'can be created' do
    operator_serving_stop = create(:operator_serving_stop)
    expect(OperatorServingStop.exists?(operator_serving_stop.id)).to be true
  end

  context 'through changesets' do
    before(:each) do
      @changeset1 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9q8yt4b-19Hollway',
              name: '19th Ave & Holloway St',
              timezone: 'America/Los_Angeles'
            }
          },
          {
            action: 'createUpdate',
            operator: {
              onestopId: 'o-9q8y-SFMTA',
              name: 'SFMTA',
              serves: ['s-9q8yt4b-19Hollway']
            }
          }
        ]
      })
    end

    it 'can be created' do
      @changeset1.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-19Hollway').operators).to include Operator.find_by_onestop_id!('o-9q8y-SFMTA')
      expect(Operator.find_by_onestop_id!('o-9q8y-SFMTA').stops).to include Stop.find_by_onestop_id!('s-9q8yt4b-19Hollway')
      expect(@changeset1.stops_created_or_updated).to match_array([
        Stop.find_by_onestop_id!('s-9q8yt4b-19Hollway')
      ])
      expect(@changeset1.operators_created_or_updated).to match_array([
        Operator.find_by_onestop_id!('o-9q8y-SFMTA')
      ])
      expect(@changeset1.operators_serving_stop_created_or_updated).to match_array([
        OperatorServingStop.find_by_attributes({ operator_onestop_id: 'o-9q8y-SFMTA', stop_onestop_id: 's-9q8yt4b-19Hollway'})
      ])
    end

    it 'can be destroyed' do
      @changeset1.apply!
      changeset2 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            operator: {
              onestopId: 'o-9q8y-SFMTA',
              doesNotServe: ['s-9q8yt4b-19Hollway']
            }
          }
        ]
      })
      changeset2.apply!
      expect(OperatorServingStop.count).to eq 0
      expect(OldOperatorServingStop.count).to eq 1
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-19Hollway').operators.count).to eq 0
    end

    it 'will be removed when stop is destroyed' do
      @changeset1.apply!
      changeset2 = create(:changeset, payload: {
        changes: [
          {
            action: 'destroy',
            stop: {
              onestopId: 's-9q8yt4b-19Hollway'
            }
          }
        ]
      })
      changeset2.apply!
      expect(OperatorServingStop.count).to eq 0
      expect(OldOperatorServingStop.count).to eq 1
      expect(Operator.find_by_onestop_id!('o-9q8y-SFMTA').stops.count).to eq 0
      expect(OldOperatorServingStop.first.stop).to be_a OldStop
      expect(OldStop.first.old_operators_serving_stop.first.operator).to eq Operator.find_by_onestop_id!('o-9q8y-SFMTA')
    end

    it 'will be removed when operator is destroyed' do
      @changeset1.apply!
      changeset2 = create(:changeset, payload: {
        changes: [
          {
            action: 'destroy',
            operator: {
              onestopId: 'o-9q8y-SFMTA'
            }
          }
        ]
      })
      changeset2.apply!
      expect(OperatorServingStop.count).to eq 0
      expect(OldOperatorServingStop.count).to eq 1
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-19Hollway').operators.count).to eq 0
      expect(OldOperatorServingStop.first.operator).to be_a OldOperator
      expect(OldOperatorServingStop.first.stop).to eq Stop.find_by_onestop_id!('s-9q8yt4b-19Hollway')
    end
  end
end
