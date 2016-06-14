# == Schema Information
#
# Table name: current_stop_transfers
#
#  id                                 :integer          not null, primary key
#  transfer_type                      :string
#  min_transfer_time                  :integer
#  tags                               :hstore
#  stop_id                            :integer
#  to_stop_id                         :integer
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#
# Indexes
#
#  index_current_stop_transfers_on_min_transfer_time  (min_transfer_time)
#  index_current_stop_transfers_on_stop_id            (stop_id)
#  index_current_stop_transfers_on_to_stop_id         (to_stop_id)
#  index_current_stop_transfers_on_transfer_type      (transfer_type)
#

describe Stop do
  context 'stop_transfers' do
    before(:each) {
      @payload = {
        changes: [
          {
            action: "createUpdate",
            stop: {
              onestopId: 's-9q9-test',
              name: 'Test Stop',
              timezone: 'America/Los_Angeles'
            }
          },
          {
            action: "createUpdate",
            stopEgress: {
              onestopId: 's-9q9-test>egress',
              timezone: 'America/Los_Angeles',
              parentStopOnestopId: 's-9q9-test'
            }
          },
          {
            action: "createUpdate",
            stopPlatform: {
              onestopId: 's-9q9-test<platform',
              timezone: 'America/Los_Angeles',
              parentStopOnestopId: 's-9q9-test'
            }
          }
        ]
      }
    }
    it 'can be created by a changeset' do
      @payload[:changes] << {
        action: 'createUpdate',
        stop: {
          onestopId: 's-9q9-test',
          includesStopTransfers: [
            {
              originOnestopId: 's-9q9-test>egress',
              destinationOnestopId: 's-9q9-test<platform',
              connectionType: 'allowed'
            }
          ]
        }
      }
      changeset = build(:changeset, payload: @payload)
      changeset.apply!
      stop = Stop.find_by_onestop_id!('s-9q9-test')
      expect(stop.stop_transfers.size).to eq(1)
    end
  end
end
