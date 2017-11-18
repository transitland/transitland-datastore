task :tile_export, [:tilepath, :thread_count] => [:environment] do |t, args|
  args.with_default(thread_count: 1)
  fail Exception.new('tilepath required') unless args[:tilepath].presence
  TileExportService.export_tiles(args[:tilepath], thread_count: args[:thread_count].to_i)
end
