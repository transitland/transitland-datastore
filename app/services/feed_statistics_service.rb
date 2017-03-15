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
  end

  def add(entity)
    self.add_value(entity.instance_variable_get(self.instance_variable))
  end

  def as_json
    sorted_values = self.unique.sort
    {
      total: self.total,
      unique: sorted_values.size,
      min: sorted_values.first,
      max: sorted_values.last
    }
  end
end

class FeedStatisticsService
  include Singleton

  def self.stats_for_model_collection(gtfs, model_cls)
    columns = nil
    model_stats = []
    gtfs.send("each_#{model_cls}") do |entity|
      if columns.nil?
        columns = entity.instance_variables - [:@feed]
        model_stats = columns.map { |i| ColumnStatistics.new(i) }
      end
      model_stats.each do |model_stat|
        model_stat.add(entity)
      end
    end
    model_stats
  end

  def self.generate_statistics(gtfs)
    stats = {}
    GTFS::Source::SOURCE_FILES.each do |model_filename, model_cls|
      next unless gtfs.file_present?(model_filename)
      model_filename = model_cls.filename
      model_cls_name = model_cls.singular_name
      model_stats = stats_for_model_collection(gtfs, model_cls_name)
      stats[model_filename] = Hash[model_stats.map { |i| [i.name, i.output] }]
    end
    stats["filenames"] = Dir.entries(gtfs.path) - ['.','..']
    stats
  end

  def self.run_statistics(feed_version)
    # Generate statistics
    gtfs = feed_version.open_gtfs
    generate_statistics(gtfs)
  end
end
