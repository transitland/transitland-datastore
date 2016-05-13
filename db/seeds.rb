# By default, no seed data is imported.
# But you can optionally do so using the rake tasks
# defined in tasks/load_seed_data.rake
IssueType.create(type_name: 'stop_route_distance_gap', description: "Distance between Route and Stop too large", category: 'geometry')
