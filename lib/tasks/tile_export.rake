task :tile_export, [:tilepath] => [:environment] do |t, args|
  fail Exception.new('tilepath required') unless args[:tilepath].presence
  TileExportService.export_tiles(args[:tilepath])
end
