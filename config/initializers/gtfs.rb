# Patch gtfs to skip costly renaming in stop_times.txt
# ~3x performance improvement
require 'gtfs'

module GTFS
  class StopTime
    def self.parse_model(attr_hash, options={})
      self.new(attr_hash)
    end
  end

  module Model
    module ClassMethods
      def each(filename)
        CSV.foreach(filename, :headers => true, :encoding => 'bom|utf-8') do |row|
          yield parse_model(row.to_hash)
        end
      end
    end
  end

end
