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

  def output
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

  def self.generate_statistics(feed_version)
    # Copy file
    gtfs_filename = feed_version.file.local_path_copying_locally_if_needed
    fail Exception.new('FeedVersion has no file attachment') unless gtfs_filename

    # Generate statistics

    # Cleanup
    feed_version.file.remove_any_local_cached_copies

    # Return
    feed_version
  end
end
