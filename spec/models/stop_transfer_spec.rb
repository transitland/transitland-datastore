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

describe StopTransfer do
  context 'stop_transfers' do
    let(:stop1) { create(:stop) }
    let(:stop2) { create(:stop) }

    it 'can be created by a changeset' do
      payload = {changes: []}
      payload = {changes: [
        action: 'createUpdate',
        stop: {
          onestopId: stop1.onestop_id,
          includesStopTransfers: [
            {
              toStopOnestopId: stop2.onestop_id,
              transferType: '0',
              minTransferTime: 60
            }
          ]
        }
      ]}
      changeset = build(:changeset, payload: payload)
      changeset.apply!
      expect(stop1.reload.stop_transfers.size).to eq(1)
    end

    it 'can be updated by a changeset' do
      stop1.stop_transfers.create(to_stop: stop2, transfer_type: '0', min_transfer_time: 60)
      expect(stop1.reload.stop_transfers.size).to eq(1)
      expect(stop1.reload.stop_transfers.first.to_stop).to eq(stop2)
      expect(stop1.reload.stop_transfers.first.min_transfer_time).to eq(60)
      payload = {changes: [
        action: 'createUpdate',
        stop: {
          onestopId: stop1.onestop_id,
          includesStopTransfers: [
            {
              toStopOnestopId: stop2.onestop_id,
              minTransferTime: 120,
            }
          ]
        }
      ]}
      changeset = build(:changeset, payload: payload)
      changeset.apply!
      expect(stop1.reload.stop_transfers.size).to eq(1)
      expect(stop1.reload.stop_transfers.first.min_transfer_time).to eq(120)
    end

    it 'can be deleted by a changeset' do
      stop1.stop_transfers.create(to_stop: stop2, transfer_type: '0', min_transfer_time: 60)
      expect(stop1.reload.stop_transfers.size).to eq(1)
      payload = {changes: [
        action: 'createUpdate',
        stop: {
          onestopId: stop1.onestop_id,
          doesNotIncludeStopTransfers: [
            {
              toStopOnestopId: stop2.onestop_id,
            }
          ]
        }
      ]}
      changeset = build(:changeset, payload: payload)
      changeset.apply!
      expect(stop1.reload.stop_transfers.size).to eq(0)
    end
  end
end
