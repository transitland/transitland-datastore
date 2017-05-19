class ColumnStatistics
  attr_accessor :name
  attr_accessor :instance_variable
  attr_accessor :total
  attr_accessor :unique

  def initialize(name)
    self.name = name.to_s.sub('@','').to_sym
    self.instance_variable = name
    self.total = 0
    self.unique = Set.new
  end

  def add_value(value)
    return if value.nil?
    self.total += 1
    self.unique << value
    value
  end

  def add(entity)
    self.add_value(entity.instance_variable_get(self.instance_variable))
  end

  def as_json(options={})
    sorted_values = self.unique.sort
    {
      total: self.total,
      unique: sorted_values.size,
      min: sorted_values.first,
      max: sorted_values.last
    }
  end
end

class StopTimeArrivalTimeStatistics < ColumnStatistics
  attr_accessor :trip_times

  def initialize(name)
    super
    self.trip_times = {}
  end

  def add(entity)
    value = super
    return if value.nil?
    self.trip_times[entity.trip_id] ||= Set.new
    self.trip_times[entity.trip_id] << value.to_sym
  end

  def trip_durations
    trip_durations = {}
    self.trip_times.each do |trip,times|
      times = times.map { |t| GTFS::WideTime.parse(t.to_s).to_seconds }.sort
      trip_durations[trip] = times.last - times.first
    end
    trip_durations
  end
end

class GTFSStatisticsService
  include Singleton

  def self.stats_for_filename_column(model_cls, column)
    column = column.to_s.sub('@','').to_sym
    model_columns = {
      GTFS::StopTime => {
        :arrival_time => StopTimeArrivalTimeStatistics
      }
    }
    return (model_columns[model_cls] || {})[column] || ColumnStatistics
  end

  def self.stats_for_model_collection(gtfs, model_cls)
    columns = nil
    model_stats = []
    gtfs.send("each_#{model_cls.singular_name}") do |entity|
      if columns.nil?
        columns = entity.instance_variables - [:@feed]
        model_stats = columns.map { |i| stats_for_filename_column(model_cls, i).new(i) }
      end
      model_stats.each do |model_stat|
        model_stat.add(entity)
      end
    end
    model_stats
  end

  def self.stats_for_service_hours(gtfs, arrival_time_stats)
    # Get service periods and start/end dates
    gtfs.load_service_periods
    service_start, service_end = gtfs.service_period_range
    service_periods = gtfs.instance_variable_get('@service_periods').values # ugly
    # Calculate trip durations
    trip_durations = arrival_time_stats.trip_durations
    # Frequency
    frequency_multiplier = {}
    if gtfs.file_present?('frequencies.txt')
      gtfs.each_frequency do |f|
        t1 = GTFS::WideTime.parse(f.start_time).to_seconds
        t2 = GTFS::WideTime.parse(f.end_time).to_seconds
        h = f.headway_secs.to_i
        frequency_multiplier[f.trip_id] ||= 0
        frequency_multiplier[f.trip_id] += (t2-t1)/h
      end
    end
    # Group trips by service_id
    trip_service_ids = {}
    gtfs.each_trip do |trip|
      trip_service_ids[trip.service_id] ||= []
      trip_service_ids[trip.service_id] << trip.id
    end
    # Calculate service time for each day
    results = {}
    now = service_start
    until now >= service_end
      sps = service_periods.select { |i| i.service_on_date?(now) }
      sps_trips = sps.map { |i| trip_service_ids.fetch(i.id, []) }.flatten
      sps_trip_times = sps_trips.map { |i| trip_durations.fetch(i, 0) * frequency_multiplier.fetch(i, 1) }
      sps_service_time = sps_trip_times.flatten.sum
      key = now.strftime('%Y-%m-%d')
      results[key] ||= 0
      results[key] += sps_service_time
      now += 1.day
    end
    results
  end

  def self.generate_statistics(gtfs)
    statistics = {}
    GTFS::Source::SOURCE_FILES.each do |model_filename, model_cls|
      next unless gtfs.file_present?(model_filename)
      model_filename = model_cls.filename
      model_cls_name = model_cls.singular_name
      model_stats = stats_for_model_collection(gtfs, model_cls)
      statistics[model_filename] = Hash[model_stats.map { |i| [i.name, i] }]
    end

    # Filenames
    filenames = gtfs.source_filenames

    # Service hours -- use already parsed trip durations
    scheduled_service = self.stats_for_service_hours(gtfs, statistics['stop_times.txt'][:arrival_time])

    # Return
    {
      statistics: statistics,
      filenames: filenames,
      scheduled_service: scheduled_service
    }
  end

  def self.create_feed_version_info(feed_version)
    # Generate statistics
    gtfs = feed_version.open_gtfs
    data = generate_statistics(gtfs)
    FeedVersionInfo.connection
    # Remove previous
    feed_version.feed_version_infos.where(type: 'FeedVersionInfoStatistics').delete_all
    feed_version.feed_version_infos.create!(type: 'FeedVersionInfoStatistics', data: data)
  end
end
