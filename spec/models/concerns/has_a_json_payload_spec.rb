describe HasAJsonPayload do
  class PseudoModel
    attr_accessor :payload
    def self.after_update(method)
      true
    end
    include HasAJsonPayload
  end

  it 'converts camelCasedKeys to underscored_keys' do
    test_model = PseudoModel.new
    test_model.payload = {
      "changes" => [
        {
          "action" => "createUpdate",
          "stop" => {
            "onestopId" => "s-9q8yt4b-1AvHoS",
            "tags" => {
              "hasABusShelter" => true
            }
          }
        }
      ]
    }
    expect(test_model.payload_as_ruby_hash).to eq({
      changes: [
        {
          action: "createUpdate",
          stop: {
            onestop_id: "s-9q8yt4b-1AvHoS",
            tags: {
              has_a_bus_shelter: true
            }
          }
        }
      ]
    })
  end
end
