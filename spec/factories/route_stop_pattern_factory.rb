FactoryGirl.define do

  factory :route_stop_pattern, class: RouteStopPattern do
    geometry { RouteStopPattern::GEOFACTORY.line_string([
      Stop::GEOFACTORY.point(-122.353165, 37.936887),
      Stop::GEOFACTORY.point(-122.38666, 37.599787)
    ])}
    stop_pattern {[create(:stop).onestop_id, create(:stop).onestop_id]}
    version 1
    association :route, factory: :route
    after(:build) { |rsp|
      puts
      rsp.onestop_id = OnestopId.handler_by_model(RouteStopPattern).new(
      route_onestop_id: "#{rsp.route.onestop_id}",
      stop_pattern: rsp.stop_pattern,
      geometry_coords: rsp.geometry[:coordinates]
    )}
  end

  factory :route_stop_pattern_bart, class: RouteStopPattern do
    geometry { RouteStopPattern.line_string([
      [-122.353165, 37.936887],
      [-122.38666, 37.599787]
    ])}
    stop_pattern {[
      create(:stop, onestop_id: 's-9q8zzf1nks-richmond').onestop_id,
      create(:stop, onestop_id: 's-9q8vzhbf8h-millbrae').onestop_id
    ]}
    version 1
    association :route, factory: :route, onestop_id: 'r-9q8y-richmond~dalycity~millbrae', name: 'Richmond - Daly City/Millbrae'
    after(:build) { |rsp_bart|
      rsp_bart.onestop_id = OnestopId.handler_by_model(RouteStopPattern).new(
      route_onestop_id: "#{rsp_bart.route.onestop_id}",
      stop_pattern: rsp_bart.stop_pattern,
      geometry_coords: rsp_bart.geometry[:coordinates]
    )}
  end
end
