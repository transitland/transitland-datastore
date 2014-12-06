class ImportFromGtfs
  attr_accessor :gtfs

  def initialize(file_path)
    @gtfs = GTFS::Source.build(file_path) # {strict: false}) ?
    @file_name = File.basename(file_path)
  end

  def import
    @gtfs.stops.each do |gtfs_stop|
      stop = Stop.match_against_existing_or_create({
        name: gtfs_stop.name,
        geometry: "POINT(#{gtfs_stop.lon} #{gtfs_stop.lat})"
      })

      if gtfs_stop.id.present?
        identifier = stop.identifiers.find_or_initialize_by(identifier: gtfs_stop.id)
        identifier.update(tags: {
          gtfs_source: @file_name,
          gtfs_column: 'id'
        })
      end

      if gtfs_stop.code.present?
        identifier = stop.identifiers.find_or_initialize_by(identifier: gtfs_stop.code)
        identifier.update(tags: {
          gtfs_source: @file_name,
          gtfs_column: 'code'
        })
      end

      yield if block_given?
    end
  end
end
