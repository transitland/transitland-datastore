ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'GTFS'
  inflect.irregular 'operator_serving_stop', 'operators_serving_stop'
  inflect.irregular 'route_serving_stop', 'routes_serving_stop'
  inflect.irregular 'route_serving_stop', 'routes_serving_stop'
  inflect.irregular 'entity_imported_from_feed', 'entities_imported_from_feed'
  inflect.irregular 'operator_in_feed', 'operators_in_feed'
  inflect.irregular 'entity_with_issues', 'entities_with_issues'
  inflect.irregular 'stop_platform', 'stop_platforms'
  inflect.irregular 'stop_egress', 'stop_egresses'
end
