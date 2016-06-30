describe StopPlatform do
  context 'serving_stop_and_platform' do
    it 'aggregates operators and routes' do
      stop_platform = create(:stop_platform)
      parent_stop = stop_platform.parent_stop
      oss = []
      oss << create(:operator_serving_stop, stop: parent_stop)
      oss << create(:operator_serving_stop, stop: stop_platform)
      rss = []
      rss << create(:route_serving_stop, stop: parent_stop)
      rss << create(:route_serving_stop, stop: stop_platform)
      expect(parent_stop.operators_serving_stop_and_platforms.pluck(:operator_id)).to match_array(oss.map(&:operator_id))
      expect(parent_stop.routes_serving_stop_and_platforms.pluck(:route_id)).to match_array(rss.map(&:route_id))
    end
  end

  context 'changeset' do
    it 'can be created' do
      stop = create(:stop)
      onestop_id = "#{stop.onestop_id}<test"
      payload = {changes: [{
        action: 'createUpdate',
        stopPlatform: {
          onestopId: onestop_id,
          timezone: 'America/Los_Angeles',
          parentStopOnestopId: stop.onestop_id
        }
      }]}
      changeset = Changeset.create(payload: payload)
      changeset.apply!
      stop_platform = StopPlatform.find_by_onestop_id!(onestop_id)
      expect(stop_platform.onestop_id).to eq(onestop_id)
      expect(stop_platform.parent_stop).to eq(stop)
    end

    it 'can be associated with a different parent stop' do
      stop1 = create(:stop)
      stop2 = create(:stop)
      stop_platform = StopPlatform.create!(
        onestop_id: "#{stop1.onestop_id}<test",
        timezone: stop1.timezone,
        parent_stop: stop1
      )
      payload = {changes: [{
        action: 'createUpdate',
        stopPlatform: {
          onestopId: stop_platform.onestop_id,
          parentStopOnestopId: stop2.onestop_id
        }
      }]}
      expect(stop_platform.parent_stop).to eq(stop1)
      changeset = Changeset.create(payload: payload)
      changeset.apply!
      expect(stop_platform.reload.parent_stop).to eq(stop2)
    end

    it 'requires parentStopOnestopId' do
      payload = {changes: [{
        action: 'createUpdate',
        stopPlatform: {
          onestopId: 's-123-foo<bar',
          timezone: 'America/Los_Angeles',
        }
      }]}
      changeset = Changeset.create()
      changeset.change_payloads.create!(payload: payload)
      expect{changeset.apply!}.to raise_error(Changeset::Error)
    end

    it 'requires valid parentStopOnestopId' do
      payload = {changes: [{
        action: 'createUpdate',
        stopPlatform: {
          onestopId: 's-123-foo<bar',
          timezone: 'America/Los_Angeles',
          parentStopOnestopId: 's-123-foo'
        }
      }]}
      changeset = Changeset.create()
      changeset.change_payloads.create!(payload: payload)
      expect{changeset.apply!}.to raise_error(Changeset::Error)
    end
  end
end
