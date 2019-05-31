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
              name: '1st Ave. & Holloway St.',
              timezone: 'America/Los_Angeles',
              geometry: { type: 'Point', coordinates: [10.195312, 43.755225] }
            }
          }
        ]
      }
      changeset = build(:changeset, payload: payload)
      expect(changeset.change_payloads.count).equal?(1)
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
              name: '1st Ave. & Holloway Street',
              timezone: 'America/Los_Angeles',
              geometry: { type: 'Point', coordinates: [10.195312, 43.755225] }
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
              name: '1st Ave. & Holloway St.',
              timezone: 'America/Los_Angeles',
              geometry: { type: 'Point', coordinates: [10.195312, 43.755225] }
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
              timezone: 'America/Los_Angeles',
              geometry: { type: 'Point', coordinates: [10.195312, 43.755225] }
            }
          }
        ]
      })
      @changeset3 = create(:changeset, payload: {
        changes: [
          {
            action: 'destroy',
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              timezone: 'America/Los_Angeles',
              geometry: { type: 'Point', coordinates: [10.195312, 43.755225] }
            }
          }
        ]
      })
    end

    it 'trial_succeeds?' do
      @changeset1.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').name).to eq '1st Ave. & Holloway Street'
      expect(@changeset2.applied).to eq false
      expect(@changeset2.trial_succeeds?).to eq [true, []]
      expect(@changeset2.reload.applied).to eq false
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').name).to eq '1st Ave. & Holloway Street'
      expect(@changeset2_bad.trial_succeeds?).to eq [false, []]
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
              serves: ['s-9q8yt4b-1AvHoS'],
              geometry: { type: 'Point', coordinates: [10.195312, 43.755225] }
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

    # it 'saves error if failed' do
    #   expect { @changeset2_bad.apply! }.to raise_error(Changeset::Error)
    #   @changeset2_bad.reload
    #   expect(@changeset2_bad.applied).to be false
    #   expect(@changeset2_bad.error).to be_truthy
    # end

    it 'changes onestop id' do
      @changeset1.apply!
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'changeOnestopID',
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              newOnestopId: 's-9q8yt4b-test'
            }
          }
        ]
      })
      changeset.apply!
      expect(Stop.find_by_current_and_old_onestop_id!('s-9q8yt4b-1AvHoS')).to eq Stop.find_by_current_and_old_onestop_id!('s-9q8yt4b-test')
      expect(Stop.all).to match_array([Stop.find_by_current_and_old_onestop_id!('s-9q8yt4b-test')])
      expect(OldStop.first).to eq OldStop.find_by_onestop_id!('s-9q8yt4b-1AvHoS')
      expect(OldStop.first.action).to eq 'change_onestop_id'
    end

    it 'raises changeset error when changing onestop id is equal to the target' do
      @changeset1.apply!
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'changeOnestopID',
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              newOnestopId: Stop.first.onestop_id
            }
          }
        ]
      })
      expect { changeset.apply! }.to raise_error(Changeset::Error)
    end

    it 'raises changeset error when onestopIdsToMerge not included' do
      @changeset1.apply!
      merge_stop_1 = create(:stop)
      merge_stop_2 = create(:stop)
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'merge',
            stop: {
              onestopId: Stop.first.onestop_id
            }
          }
        ]
      })
      expect { changeset.apply! }.to raise_error(Changeset::Error)
    end

    it 'raises changeset error when onestopIdsToMerge includes target onestop id' do
      @changeset1.apply!
      merge_stop_1 = create(:stop)
      merge_stop_2 = create(:stop)
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'merge',
            onestopIdsToMerge: [merge_stop_1.onestop_id, merge_stop_2.onestop_id],
            stop: {
              onestopId: merge_stop_1.onestop_id
            }
          }
        ]
      })
      expect { changeset.apply! }.to raise_error(Changeset::Error)
    end

    it 'merges onestop id for an existing entity' do
      @changeset1.apply!
      merge_stop_1 = create(:stop)
      merge_stop_2 = create(:stop)
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'merge',
            onestopIdsToMerge: [merge_stop_1.onestop_id, merge_stop_2.onestop_id],
            stop: {
              onestopId: Stop.first.onestop_id
            }
          }
        ]
      })
      changeset.apply!
      expect(Stop.find_by_current_and_old_onestop_id!(merge_stop_1.onestop_id)).to eq Stop.first
      expect(Stop.find_by_current_and_old_onestop_id!(merge_stop_2.onestop_id)).to eq Stop.first
      expect(Stop.all).to match_array([Stop.find_by_current_and_old_onestop_id!('s-9q8yt4b-1AvHoS')])
      expect(OldStop.find_by_onestop_id!(merge_stop_1.onestop_id)).to be
      expect(OldStop.last).to eq OldStop.find_by_onestop_id!(merge_stop_2.onestop_id)
      expect(OldStop.last.current).to eq Stop.first
      expect(OldStop.last.action).to eq 'merge'
    end

    it 'merges onestop id for a new entity' do
      merge_stop_1 = create(:stop)
      merge_stop_2 = create(:stop)
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'merge',
            onestopIdsToMerge: [merge_stop_1.onestop_id, merge_stop_2.onestop_id],
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              name: '1st Ave. & Holloway Street',
              timezone: 'America/Los_Angeles',
              geometry: { type: 'Point', coordinates: [10.195312, 43.755225] }
            }
          }
        ]
      })
      changeset.apply!
      expect(Stop.find_by_current_and_old_onestop_id!(merge_stop_1.onestop_id)).to eq Stop.first
      expect(Stop.find_by_current_and_old_onestop_id!(merge_stop_2.onestop_id)).to eq Stop.first
      expect(Stop.first).to eq Stop.find_by_current_and_old_onestop_id!('s-9q8yt4b-1AvHoS')
      expect(OldStop.first).to eq OldStop.find_by_onestop_id!(merge_stop_1.onestop_id)
      expect(OldStop.last).to eq OldStop.find_by_onestop_id!(merge_stop_2.onestop_id)
      expect(OldStop.last.current).to eq Stop.first
      expect(OldStop.last.action).to eq 'merge'
    end

    it 'allows createUpdate changes to current entity target of a changeOnestopID action, using the old onestop id' do
      stop = create(:stop)
      old_onestop_id = stop.onestop_id
      change_id_changeset = create(:changeset, payload: {
       changes: [
         {
           action: 'changeOnestopID',
           stop: {
             onestopId: old_onestop_id,
             newOnestopId: 's-9q8yt4b-new'
           }
         }
       ]
      })
      change_id_changeset.apply!
      changeset = create(:changeset, payload: {
       changes: [
         {
           action: 'createUpdate',
           stop: {
             onestopId: old_onestop_id,
             name: 'A new name'
           }
         }
       ]
      })
      changeset.apply!
      expect{Stop.find_by_onestop_id!(old_onestop_id)}.to raise_error(ActiveRecord::RecordNotFound)
      expect(Stop.first.name).to eq 'A new name'
    end

    it 'allows createUpdate changes to current entity target of merge action, using the old onestop id' do
      merge_stop_1 = create(:stop)
      merge_stop_2 = create(:stop)
      merge_changeset = create(:changeset, payload: {
       changes: [
         {
           action: 'merge',
           onestopIdsToMerge: [merge_stop_1.onestop_id, merge_stop_2.onestop_id],
           stop: {
             onestopId: 's-9q8yt4b-1AvHoS',
             name: '1st Ave. & Holloway Street',
             timezone: 'America/Los_Angeles',
             geometry: { type: 'Point', coordinates: [10.195312, 43.755225] }
           }
         }
       ]
      })
      merge_changeset.apply!
      changeset = create(:changeset, payload: {
       changes: [
         {
           action: 'createUpdate',
           stop: {
             onestopId: merge_stop_1.onestop_id,
             name: 'A new name'
           }
         }
       ]
      })
      changeset.apply!
      expect{Stop.find_by_onestop_id!(merge_stop_1.onestop_id)}.to raise_error(ActiveRecord::RecordNotFound)
      expect(Stop.first.name).to eq 'A new name'
    end

    it 'preserves merge action result after subsequent import' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_example, import_level: 1)
      feed_version.feed_version_imports.create(
        import_level: 1
      )
      stop1, stop2, merge_into_stop = Stop.take(3)

      merge_changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'merge',
            onestopIdsToMerge: [stop1.onestop_id, stop2.onestop_id],
            stop: {
              onestopId: merge_into_stop.onestop_id,
              name: 'Merged stop.'
            }
          }
        ]
      })
      merge_changeset.apply!
      # the changeset imported_from_feed needs to have >1 feed_version_imports for attributes to stick
      FeedEaterWorker.new.perform(feed.onestop_id, feed_version.sha1=nil, import_level=1)
      expect(Stop.find_by_onestop_id!(merge_into_stop.onestop_id).name).to eq 'Merged stop.'
      expect(Stop.find_by_current_and_old_onestop_id!(stop1.onestop_id)).to eq Stop.find_by_onestop_id!(merge_into_stop.onestop_id)
    end

    it 'updates rsp stop pattern stop onestop ids on merge onestop ids' do
      richmond = create(:stop_richmond_offset)
      millbrae = create(:stop_millbrae)
      rsp = create(:route_stop_pattern_bart)
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'merge',
            onestopIdsToMerge: [richmond.onestop_id],
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              geometry: { type: 'Point', coordinates: [-122.35073, 37.95234] }, # tiny change to existing
              timezone: 'America/Los_Angeles',
            }
          }
        ]
      })
      changeset.apply!
      expect(RouteStopPattern.find_by_onestop_id!(rsp.onestop_id).stop_pattern).to match_array(['s-9q8yt4b-1AvHoS', millbrae.onestop_id])
    end

    it 'updates rsp stop pattern onestop ids on change onestop id action' do
      richmond = create(:stop_richmond_offset)
      millbrae = create(:stop_millbrae)
      rsp = create(:route_stop_pattern_bart)
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'changeOnestopID',
            stop: {
              onestopId: richmond.onestop_id,
              newOnestopId: 's-9q8yt4b-1AvHoS'
            }
          }
        ]
      })
      changeset.apply!
      expect(RouteStopPattern.find_by_onestop_id!(rsp.onestop_id).stop_pattern).to match_array(['s-9q8yt4b-1AvHoS', millbrae.onestop_id])
    end

    it 'sets action to destroy after destroy' do
      @changeset1.apply!
      @changeset3.apply!
      expect(OldStop.first.action).to eq 'destroy'
    end
  end

  context 'sticky and edited attributes' do
    # import-related changeset integration tests are in gtfs_graph_spec
    before(:each) {
      @onestop_id = 's-9q8yt4b-1AvHoS'
      @changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: @onestop_id,
              name: '1st Ave. & Holloway St.',
              timezone: 'America/Los_Angeles',
              geometry: { type: 'Point', coordinates: [10.195312, 43.755225] }
            }
          }
        ]
      })
      @changeset.apply!
    }

    it 'updates edited_attributes during create and update' do
      stop = Stop.find_by_onestop_id!(@onestop_id)
      stop.wheelchair_boarding = true
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: @onestop_id,
              wheelchairBoarding: true
            }
          }
        ]
      })
      changeset.apply!
      expect(Stop.find_by_onestop_id!(stop.onestop_id).edited_attributes).to include("wheelchair_boarding")
    end

    it 'allows non-import changeset to preserve sticky and edited attributes' do
      edited_attrs = Set.new(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').edited_attributes.map(&:to_sym))
      expect(Set.new(Stop.sticky_attributes)).to satisfy { |st| edited_attrs.subset?(st) }
    end

    it 'allows non-import changeset to write over attributes of previous non-import changeset' do
      changeset2 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              name: 'Second Edit',
              timezone: 'America/Los_Angeles',
              geometry: { type: 'Point', coordinates: [10.195312, 43.755225] }
            }
          }
        ]
      })
      changeset2.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').name).to eq 'Second Edit'
    end

    it 'allows change onestop id changeset action to preserve sticky and edited attributes' do
      changeset2 = create(:changeset, payload: {
        changes: [
          {
            action: 'changeOnestopID',
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              newOnestopId: 's-9q8yt4b-changedId',
              name: 'A new name.'
            }
          }
        ]
      })
      changeset2.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-changedId').edited_attributes).to include("name")
    end
  end

  context 'changeStopType' do
    let(:parent_stop) { create(:stop) }
    let(:stop) { create(:stop) }
    let(:stop_id) { stop.id }
    let(:platform_name) { "test" }

    it 'tracks change' do
      stop_type = 'StopPlatform'
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'changeStopType',
            stop: {
              onestopId: stop.onestop_id,
              stopType: stop_type,
              platformName: platform_name,
              parentStopOnestopId: parent_stop.onestop_id
            }
          }
        ]
      })
      expect(stop.version).to eq(1)
      changeset.apply!
      stop = Stop.find(stop_id)
      # Creates two change records
      expect(stop.version).to eq(3)
      expect(OldStop.where(current_id: stop.id).pluck(:action)).to match_array(['change_onestop_id', 'change_stop_type'])
    end

    it 'changes from Stop to StopPlatform' do
      stop_type = 'StopPlatform'
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'changeStopType',
            stop: {
              onestopId: stop.onestop_id,
              stopType: stop_type,
              platformName: platform_name,
              parentStopOnestopId: parent_stop.onestop_id
            }
          }
        ]
      })
      changeset.apply!
      stop = Stop.find(stop_id)
      expect(stop.type).to eq(stop_type)
      expect(stop.parent_stop).to eq(parent_stop)
      expect(stop.onestop_id).to start_with(parent_stop.onestop_id)
      expect(stop.onestop_id).to eq("#{parent_stop.onestop_id}<#{platform_name}")
    end

    it 'changes from Stop to StopEgress' do
      stop_type = 'StopEgress'
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'changeStopType',
            stop: {
              onestopId: stop.onestop_id,
              stopType: stop_type,
              platformName: platform_name,
              parentStopOnestopId: parent_stop.onestop_id
            }
          }
        ]
      })
      changeset.apply!
      stop = Stop.find(stop_id)
      expect(stop.type).to eq(stop_type)
      expect(stop.parent_stop).to eq(parent_stop)
      expect(stop.onestop_id).to start_with(parent_stop.onestop_id)
      expect(stop.onestop_id).to eq("#{parent_stop.onestop_id}>#{platform_name}")
    end

    it 'changes from Stop to StopEgress' do
      stop = create(:stop_platform)
      stop_id = stop.id
      new_onestop_id = 's-9q9-test'
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'changeStopType',
            stop: {
              onestopId: stop.onestop_id,
              newOnestopId: new_onestop_id,
              stopType: 'Stop'
            }
          }
        ]
      })
      changeset.apply!
      stop = Stop.find(stop_id)
      expect(stop.type).to eq(nil)
      expect(stop.parent_stop).to eq(nil)
      expect(stop.onestop_id).to eq(new_onestop_id)
    end

  end

  context 'computed attributes' do
    it 'recomputes rsp stop distances from rsp update changeset' do
      richmond = create(:stop_richmond_offset)
      millbrae = create(:stop_millbrae)
      rsp = create(:route_stop_pattern_bart)
      create(:schedule_stop_pair, origin: richmond, destination: millbrae, route_stop_pattern: rsp)

      # now, a minor tweak to the first rsp geometry endpoint to demonstrate a change in stop distance for the second stop
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            routeStopPattern: {
              onestopId: 'r-9q8y-richmond~dalycity~millbrae-e8fb80-61d4dc',
              stopPattern: ['s-9q8zzf1nks-richmond', 's-9q8vzhbf8h-millbrae'],
              geometry: { type: "LineString", coordinates: [[-122.351529, 37.937750], [-122.38666, 37.599787]] }
            }
          }
        ]
      })
      changeset.apply!
      saved_ssp = ScheduleStopPair.first
      expect(saved_ssp.origin_dist_traveled).to eq 0.0
      expect(saved_ssp.destination_dist_traveled).to eq 37748.7
      expect(RouteStopPattern.find_by_onestop_id!('r-9q8y-richmond~dalycity~millbrae-e8fb80-61d4dc').stop_distances).to eq [0.0, 37748.7]
    end

    it 'recomputes rsp stop distances from stop update changeset' do
      richmond = create(:stop_richmond_offset)
      millbrae = create(:stop_millbrae)
      rsp = create(:route_stop_pattern_bart)
      create(:schedule_stop_pair, origin: richmond, destination: millbrae, route_stop_pattern: rsp)
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9q8zzf1nks-richmond',
              timezone: 'America/Los_Angeles',
              name: 'Richmond',
              geometry: { type: "Point", coordinates: [-122.353165, 37.936887] }
            }
          }
        ]
      })
      changeset.apply!
      saved_ssp = ScheduleStopPair.first
      expect(saved_ssp.origin_dist_traveled).to eq 0.0
      expect(saved_ssp.destination_dist_traveled).to eq 37641.4
      expect(RouteStopPattern.find_by_onestop_id!('r-9q8y-richmond~dalycity~millbrae-e8fb80-61d4dc').stop_distances).to eq [0.0, 37641.4]
    end

    it 'recomputes operator convex hull on stop update changeset' do
      stop = create(:stop_richmond)
      operator = create(:operator, geometry: { type: "Point", coordinates: stop.geometry[:coordinates] } )
      OperatorServingStop.new(operator: operator, stop: stop).save!
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9q8zzf1nks-richmond',
              timezone: 'America/Los_Angeles',
              name: 'Richmond',
              geometry: { type: "Point", coordinates: [-122.5, 37.9] }
            }
          }
        ]
      })
      changeset.apply!
      convex_hull_coordinates = Operator.find_by_onestop_id!(operator.onestop_id).geometry[:coordinates].first.map {|a| a.map { |b| b.round(4) } }
      expect(convex_hull_coordinates).to match_array([[-122.5003, 37.9],
                                                      [-122.5, 37.8997],
                                                      [-122.5, 37.9003],
                                                      [-122.4997, 37.9],
                                                      [-122.4997, 37.9]])
    end

    it 'recomputes route geometry on route stop pattern geometries update changeset' do
      create(:stop_richmond_offset)
      create(:stop_millbrae)
      rsp = create(:route_stop_pattern_bart)
      changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            routeStopPattern: {
              onestopId: 'r-9q8y-richmond~dalycity~millbrae-e8fb80-61d4dc',
              geometry: { type: "LineString", coordinates: [[-100, 30.0], [-122.351529, 37.937750], [-122.38666, 37.599787]] }
            }
          }
        ]
      })
      changeset.apply!
      expect(Route.find_by_onestop_id!(rsp.route.onestop_id).geometry[:coordinates].flatten(1)).to include([-100, 30.0])
    end
  end

  context 'issues' do
    before(:all) do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_example_issues, import_level: 1)
    end
    before(:each) do
      # Issues:
      # 1 - 6: rsp_line_only_stop_points
      # 7: distance_calculation_inaccurate (s-9qkxnx40xt-furnacecreekresortdemo & r-9qsb-20-8d5767-6bb5fc)
      # 8: stop_rsp_distance_gap (s-9qscwx8n60-nyecountyairportdemo & r-9qscy-30-a41e99-fcca25)
      @rsp1 = RouteStopPattern.find_by_onestop_id!('r-9qsb-20-8d5767-6bb5fc')
      @rsp2 = RouteStopPattern.find_by_onestop_id!('r-9qscy-30-a41e99-fcca25')
      @stop = Stop.find_by_onestop_id!('s-9qscwx8n60-nyecountyairportdemo')
    end
    after(:all) {
      DatabaseCleaner.clean_with :truncation, { except: ['spatial_ref_sys'] }
    }

    it 'creates geometry issues during import' do
      expect(Issue.issue_types_in_category('route_geometry').size).to be > 1
    end

    it 'sets nil values for stop distances when distance calculation issues' do
      expect(RouteStopPattern.find_by_onestop_id!('r-9qsb-20-8d5767-6bb5fc').stop_distances).to match_array([nil, nil])
    end

    context 'resolution' do
      it 'can be resolved' do
        issue = @stop.issues.first
        Timecop.freeze(3.minutes.from_now) do
          changeset = create(:changeset, payload: {
            changes: [
              action: 'createUpdate',
              issuesResolved: [issue.id],
              stop: {
                onestopId: 's-9qscwx8n60-nyecountyairportdemo',
                timezone: 'America/Los_Angeles',
                geometry: {
                  "type": "Point",
                  "coordinates": [-116.784582, 36.888446]
                }
              }
            ]
          })
          expect(Sidekiq::Logging.logger).to receive(:info).with(/Calculating distances/)
          expect(Sidekiq::Logging.logger).to receive(:info).with(/Deprecating issue: \{"id"=>#{issue.id}.*"resolved_by_changeset_id"=>.*"open"=>false/)
          changeset.apply!
        end
      end

      it 'does not apply changeset that does not resolve payload issues_resolved' do
        issue = @stop.issues.first
        Timecop.freeze(3.minutes.from_now) do
          changeset = create(:changeset, payload: {
            changes: [
              action: 'createUpdate',
              issuesResolved: [issue.id],
              stop: {
                onestopId: 's-9qscwx8n60-nyecountyairportdemo',
                timezone: 'America/Los_Angeles',
                geometry: {
                  "type": "Point",
                  "coordinates": [-100.0, 50.0]
                }
              }
            ]
          })
          expect {
            changeset.apply!
          }.to raise_error(Changeset::Error)
        end
      end

      it 'does not falsely resolve issues' do
        issue = @stop.issues.first
        Timecop.freeze(3.minutes.from_now) do
          changeset = create(:changeset, payload: {
            changes: [
              action: 'createUpdate',
              issuesResolved: [issue.id],
              stop: {
                onestopId: 's-9qsczn2rk0-emainst~sirvingstdemo',
                timezone: 'America/Los_Angeles',
                geometry: {
                  "type": "Point",
                  "coordinates": [-100.0, 50.0]
                }
              }
            ]
          })
          expect {
            changeset.apply!
          }.to raise_error(Changeset::Error)
        end
      end
    end

    context 'deprecation' do
      it 'deprecates issues of old feed version imports with the same entities' do
        issue = @rsp1.issues.first
        Timecop.freeze(3.minutes.from_now) do
          load_feed(feed_version: @feed_version, import_level: 1)
        end
        expect(Issue.count).to eq 8
        expect{Issue.find(issue.id)}.to raise_error(ActiveRecord::RecordNotFound)
        expect(@rsp1.reload.issues.first.created_by_changeset_id).to eq Changeset.last.id
      end

      it 'deprecates issues created by older changesets of associated entities' do
        issue = @stop.issues.first
        changeset = nil
        Timecop.freeze(3.minutes.from_now) do
          # NOTE: although this changeset would resolve an issue,
          # we are explicitly avoiding that just to test deprecation. Furthermore, this changeset
          # creates a similar issue (but involving a different rsp) to the
          # one being deprecated.
          changeset = create(:changeset, payload: {
            changes: [
              action: 'createUpdate',
              stop: {
                onestopId: 's-9qscwx8n60-nyecountyairportdemo',
                timezone: 'America/Los_Angeles',
                geometry: {
                  "type": "Point",
                  "coordinates": [-116.784582, 36.888446]
                }
              }
            ]
          })
          expect(Sidekiq::Logging.logger).to receive(:info).with(/Calculating distances/)
          # making sure open=true because we are not resolving the issue here
          expect(Sidekiq::Logging.logger).to receive(:info).with(/Deprecating issue: \{"id"=>#{issue.id}.*"open"=>true/)
          changeset.apply!
        end
        expect{Issue.find(issue.id)}.to raise_error(ActiveRecord::RecordNotFound)
        # similar to issue 8, but involves a different rsp
        expect(@stop.reload.issues.first.created_by_changeset_id).to eq changeset.id
      end

      it 'ignores FeedVersion issues during deprecation' do
        # duplicate the entire feed import, which should deprecate all previous imports' issues
        # except the the FeedVersion issue
        issue = Issue.create!(issue_type: 'feed_version_maintenance_extend', details: 'extend this feed')
        issue.entities_with_issues.create!(entity: FeedVersion.first)
        Timecop.freeze(3.minutes.from_now) do
          load_feed(feed_version: @feed_version, import_level: 1)
        end
        expect(Issue.find(issue.id).issue_type).to eq 'feed_version_maintenance_extend'
      end

      context 'entity attributes' do
        it 'only deprecates issues with entities_with_issues having attrs matching the changeset entity attrs' do
          # using other for now, because there is no issue type yet for wrong stop name
          stop = Stop.first
          issue = Issue.create!(issue_type: 'other', details: 'this stop name is wrong')
          issue.entities_with_issues.create!(entity: stop, entity_attribute: 'name')
          Timecop.freeze(3.minutes.from_now) do
            # changing the stop geometry - should not deprecate issues on the stop name
            changeset = create(:changeset, payload: {
              changes: [
                action: 'createUpdate',
                stop: {
                  onestopId: stop.onestop_id,
                  "geometry": {
                    "type": "Point",
                    "coordinates": [-116.784583, 36.868452]
                  }
                }
              ]
            })
            changeset.apply!
          end
          expect(Issue.find(issue.id).issue_type).to eq 'other'
          expect(Issue.find(issue.id).entities_with_issues.map(&:entity)).to include(stop)
        end

        it 'deprecates issues of entities whose attrs are affected by updating computed attrs' do
          issue = Issue.create!(issue_type: 'rsp_line_only_stop_points', details: 'this is a fake geometry issue')
          issue.entities_with_issues.create!(entity: @rsp1, entity_attribute: 'geometry')
          issues = @rsp1.reload.issues.to_a
          # here we are modifying this rsp's geometry, which should deprecate the existing rsp_line_only_stop_points issue
          # even without technically resolving it, because the entity attribute geometry has been modified.
          # The distance calculation issue (7) on this rsp should also be deprecated, because its stop distances
          # will be re-calculated in the update of computed attributes, which should also find obsolete stop distance issues.
          Timecop.freeze(3.minutes.from_now) do
            changeset = create(:changeset, payload: {
              changes: [
                action: 'createUpdate',
                routeStopPattern: {
                  onestopId: @rsp1.onestop_id,
                  geometry: {
                    "type": "LineString",
                    "coordinates": [[-117.13316, 36.42529], [-117.05, 36.65], [-116.81797, 36.88108]]
                  }
                }
              ]
            })
            expect(Sidekiq::Logging.logger).to receive(:info).with(/Calculating distances/)
            expect(Sidekiq::Logging.logger).to receive(:info).with(/Deprecating issue: \{"id"=>#{issues.first.id}.*"resolved_by_changeset_id"=>nil.*"open"=>true/)
            expect(Sidekiq::Logging.logger).to receive(:info).with(/Deprecating issue: \{"id"=>#{issues.second.id}.*"resolved_by_changeset_id"=>nil.*"open"=>true/)
            changeset.apply!
          end
        end
      end
    end
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

  context 'application e-mail' do
    it 'sent to normal user' do
      @changeset1 = create(:changeset)
      @changeset1.user = create(:user)
      @changeset1.apply!
      expect(ChangesetMailer.instance_method :application).to be_delayed(@changeset1.id)
    end

    it 'not sent to admin user' do
      @changeset1 = create(:changeset)
      @changeset1.user = create(:user, admin: true)
      @changeset1.apply!
      expect(ChangesetMailer.instance_method :application).to_not be_delayed(@changeset1.id)
    end

    it 'not sent when disabled' do
      @changeset1 = create(:changeset)
      allow(Figaro.env).to receive(:send_changeset_emails_to_users) { 'false' }
      @changeset1.user = create(:user)
      @changeset1.apply!
      expect(ChangesetMailer.instance_method :application).to_not be_delayed(@changeset1.id)
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
    stop = create(:stop)
    changeset = create(:changeset, payload: {
      changes: [
        {
          action: 'createUpdate',
          stop: {
            onestopId: stop.onestop_id,
            name: '1st Ave. & Holloway Street',
            timezone: 'America/Los_Angeles',
            geometry: { type: 'Point', coordinates: [10.195312, 43.755225] }
          }
        }
      ]
    })
    allow(StopConflateWorker).to receive(:perform_async) { true }
    # WARNING: we're expecting certain a ID in the database. This might
    # not be the case if the test suite is run in parallel.
    expect(StopConflateWorker).to receive(:perform_async).with([stop.id])
    changeset.apply!
  end
end
