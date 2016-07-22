describe HashHelpers do
  context 'merge_hashes' do
    it 'should save unchanged values' do
      existing_hash = {
        onestop_id: 'o-b7-Fake',
      }
      incoming_hash = {
        tags: {
          one: true
        }
      }
      merged_hash = HashHelpers::merge_hashes(existing_hash: existing_hash, incoming_hash: incoming_hash)
      expect(merged_hash).to eq({
        onestop_id: 'o-b7-Fake',
        tags: {
          one: true
        }
      })
    end

    it 'should handle equal values' do
      existing_hash = {
        onestop_id: 'o-b7-Fake'
      }
      incoming_hash = {
        onestop_id: 'o-b7-Fake'
      }
      merged_hash = HashHelpers::merge_hashes(existing_hash: existing_hash, incoming_hash: incoming_hash)
      expect(merged_hash).to eq({
        onestop_id: 'o-b7-Fake'
      })
    end

    it 'should convert empty strings to nil' do
      hash1 = {foo: 'bar'}
      hash2 = {foo: ''}
      merged = HashHelpers::merge_hashes(existing_hash: hash1, incoming_hash: hash2)
      expect(merged[:foo]).to be nil
    end

    it 'should replace array values' do
      existing_hash = {
        onestop_id: 'o-b7-Fake',
        names: ['Fake', 'Not Real']
      }
      incoming_hash = {
        names: ['Fake']
      }
      merged_hash = HashHelpers::merge_hashes(existing_hash: existing_hash, incoming_hash: incoming_hash)
      expect(merged_hash).to eq({
        onestop_id: 'o-b7-Fake',
        names: ['Fake']
      })
    end

    it 'should convert all keys to symbols' do
      existing_hash = {
        'onestop_id' => 'o-b7-Fake',
        tags: {
          'one' => true,
          'two' => false
        }
      }
      incoming_hash = {
        tags: {
          one: false
        }
      }
      merged_hash = HashHelpers::merge_hashes(existing_hash: existing_hash, incoming_hash: incoming_hash)
      expect(merged_hash).to eq({
        onestop_id: 'o-b7-Fake',
        tags: {
          one: false,
          two: false
        }
      })
    end
  end

  context 'update_keys' do
    it 'can go from camelCaseHash to underscored_hash' do
      camelCaseHash = {
        "changeset" => {
          "payload" => {
            "changes" => [
              {
                "action" => "createUpdate",
                "stop" => {
                  "onestopId" => "s-9q8yt4b-1AvHoS",
                  "name" => "1st Ave. & Holloway Street",
                  "tags" => {
                    "wheelchairAccessible" => true,
                    "numberOfSeats" => 5
                  },
                  "geometry" => {
                    "type" => "Point",
                    "coordinates" => [-106.5234375, 31.05293398570514]
                  }
                }
              }
            ]
          }
        }
      }
      underscored_hash = HashHelpers::update_keys(camelCaseHash, :underscore)
      expect(underscored_hash).to eq({
        changeset: {
          payload: {
            changes: [
              {
                action: "createUpdate",
                stop: {
                  onestop_id: "s-9q8yt4b-1AvHoS",
                  name: "1st Ave. & Holloway Street",
                  tags: {
                    wheelchair_accessible: true,
                    number_of_seats: 5
                  },
                  geometry: {
                    type: "Point",
                    coordinates: [-106.5234375, 31.05293398570514]
                  }
                }
              }
            ]
          }
        }
      })
    end
  end
end
