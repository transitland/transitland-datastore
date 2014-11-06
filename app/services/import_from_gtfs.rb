class ImportFromGtfs
  attr_accessor :gtfs

  def initialize(file_path)
    @gtfs = GTFS::Source.build(file_path) # {strict: false}) ?
  end

  def import
    @gtfs.stops.each do |gtfs_stop|
      stop = Stop.match_against_existing_stop_or_create({name: gtfs_stop.name,geometry: "POINT(#{gtfs_stop.lon} #{gtfs_stop.lat})"})

      if gtfs_stop.id.present?
        stop_identifier = stop.stop_identifiers.find_or_initialize_by(identifier: gtfs_stop.id)
        stop_identifier.update(tags: {
          gtfs_source: @gtfs.source,
          gtfs_column: 'id'
        })
      end

      if gtfs_stop.code.present?
        stop_identifier = stop.stop_identifiers.find_or_initialize_by(identifier: gtfs_stop.code)
        stop_identifier.update(tags: {
          gtfs_source: @gtfs.source,
          gtfs_column: 'code'
        })
      end

      yield if block_given?
    end
  end
end
