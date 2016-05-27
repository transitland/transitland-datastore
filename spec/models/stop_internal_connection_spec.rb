# == Schema Information
#
# Table name: current_stop_internal_connections
#
#  id                                 :integer          not null, primary key
#  connection_type                    :string
#  tags                               :hstore
#  stop_id                            :integer
#  origin_id                          :integer
#  destination_id                     :integer
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#
# Indexes
#
#  index_current_stop_internal_connections_on_connection_type  (connection_type)
#  index_current_stop_internal_connections_on_destination_id   (destination_id)
#  index_current_stop_internal_connections_on_origin_id        (origin_id)
#  index_current_stop_internal_connections_on_stop_id          (stop_id)
#

describe Stop do
  context 'stop_internal_connections' do
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
          includesStopInternalConnections: [
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
      expect(stop.stop_internal_connections.size).to eq(1)
    end
  end
end
