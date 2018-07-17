# == Schema Information
#
# Table name: current_stops
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  geometry                           :geography({:srid geometry, 4326
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  name                               :string
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  timezone                           :string
#  last_conflated_at                  :datetime
#  type                               :string
#  parent_stop_id                     :integer
#  osm_way_id                         :integer
#  edited_attributes                  :string           default([]), is an Array
#  wheelchair_boarding                :boolean
#  directionality                     :integer
#  geometry_reversegeo                :geography({:srid point, 4326
#
# Indexes
#
#  #c_stops_cu_in_changeset_id_index           (created_or_updated_in_changeset_id)
#  index_current_stops_on_geometry             (geometry) USING gist
#  index_current_stops_on_geometry_reversegeo  (geometry_reversegeo) USING gist
#  index_current_stops_on_onestop_id           (onestop_id) UNIQUE
#  index_current_stops_on_parent_stop_id       (parent_stop_id)
#  index_current_stops_on_tags                 (tags)
#  index_current_stops_on_updated_at           (updated_at)
#  index_current_stops_on_wheelchair_boarding  (wheelchair_boarding)
#

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
          parentStopOnestopId: stop.onestop_id,
          geometry: { type: "Point", coordinates: [-122.475075, 37.721323] }
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
      stop_platform = create(:stop_platform,
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
          geometry: { type: "Point", coordinates: [-122.475075, 37.721323] }
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
          parentStopOnestopId: 's-123-foo',
          geometry: { type: "Point", coordinates: [-122.475075, 37.721323] }
        }
      }]}
      changeset = Changeset.create()
      changeset.change_payloads.create!(payload: payload)
      expect{changeset.apply!}.to raise_error(Changeset::Error)
    end

    context 'issues' do
      before(:each) do
        @stop = create(:stop, geometry: Stop::GEOFACTORY.point(-122.401811, 37.706675).to_s)
        onestop_id = "#{@stop.onestop_id}<test"
        @payload = {changes: [{
          action: 'createUpdate',
          stopPlatform: {
            onestopId: onestop_id,
            timezone: 'America/Los_Angeles',
            parentStopOnestopId: @stop.onestop_id,
            geometry: { type: "Point", coordinates: [-122.475075, 37.721323] }
          }
        }]}
      end

      it 'creates stop platform, parent stop distance gap issues' do
        changeset = Changeset.create(payload: @payload)
        changeset.apply!
        expect(Issue.where(issue_type: 'stop_platform_parent_distance_gap').size).to be >= 1
      end

      it 'creates stop platforms too close issues' do
        other_onestop_id = "#{@stop.onestop_id}<other"
        @payload[:changes] << {
          action: 'createUpdate',
          stopPlatform: {
            onestopId: other_onestop_id,
            timezone: 'America/Los_Angeles',
            parentStopOnestopId: @stop.onestop_id,
            geometry: { type: "Point", coordinates: [-122.475075, 37.721323] }
          }
        }
        changeset = Changeset.create(payload: @payload)
        changeset.apply!
        expect(Issue.where(issue_type: 'stop_platforms_too_close').size).to eq 1
      end

      it 'identifies stop platforms too close when a sibling platform has not been modified in changeset' do
        other_onestop_id = "#{@stop.onestop_id}<other"
        @stop_platform = create(:stop_platform,
                                onestop_id: other_onestop_id,
                                parent_stop: @stop,
                                geometry: Stop::GEOFACTORY.point(-122.475075, 37.721323).to_s)
        changeset = Changeset.create(payload: @payload)
        changeset.apply!
        expect(Issue.where(issue_type: 'stop_platforms_too_close').size).to eq 1
      end
    end
  end
end
