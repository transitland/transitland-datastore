class ImportFromGtfs
  attr_accessor :gtfs

  def initialize(file_path)
    @gtfs = GTFS::Source.build(file_path) # {strict: false}) ?
  end

  def import
    @gtfs.stops.each do |stop|
      Stop.match_against_existing_stop_or_create({
        name: stop.name,
        geometry: "POINT(#{stop.lon} #{stop.lat})"
      })
      yield if block_given?
    end
  end
end
