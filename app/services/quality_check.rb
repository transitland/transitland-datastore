module GeometryQualityCheck

  def evaluate_geometries(rsps)
    rsps_with_issues = 0
    rsps.each do |rsp|
      stops = rsp.stop_pattern.map { |onestop_id| OnestopId.find!(onestop_id) }
      stops.each do |stop|
        self.stop_rsp_distance_gap(stop, rsp)
      end

      self.evaluate_distances(rsp)
      rsps_with_issues += 1 if rsp.distance_issues > 0
    end
    score = ((rsps.size - rsps_with_issues)/rsps.size.to_f).round(5) rescue score = 1.0
    # TODO feed onestop id
    puts "Feed: #{self.feed_version.sha1}. #{rsps_with_issues} Route Stop Patterns out of #{rsps.size} had issues with distance calculation. Valhalla Import Score: #{score}"
  end

  def stop_rsp_distance_gap(stop, rsp)
    if rsp.outlier_stop(stop[:geometry])
      issue = Issue.new(feed_version: self.feed_version,
                        created_by_changeset: self.changeset,
                        issue_type_id: 1,
                        details: "Stop #{stop.onestop_id} and RouteStopPattern #{rsp.onestop_id} too far apart")
      issue.entities_with_issues.new(entity: stop, issue: issue)
      issue.entities_with_issues.new(entity: rsp, issue: issue)
      self.issues << issue
    end
  end

  def evaluate_distances(rsp)
    # TODO: create issues! Remove logging
    geometry_length = rsp[:geometry].length
    rsp.stop_distances.each_index do |i|
      if (i != 0)
        if (rsp.stop_distances[i-1] == rsp.stop_distances[i])
          unless rsp.stop_pattern[i].eql? rsp.stop_pattern[i-1]
            puts "Distance issue: stop #{rsp.stop_pattern[i]}, number #{i+1}/#{rsp.stop_pattern.size}, of route stop pattern #{rsp.onestop_id} has the same distance as #{rsp.stop_pattern[i-1]}, which may indicate a segment matching issue or outlier stop."
            rsp.distance_issues += 1
          end
        elsif (rsp.stop_distances[i-1] > rsp.stop_distances[i])
          puts "Distance issue: stop #{rsp.stop_pattern[i]}, number #{i+1}/#{rsp.stop_pattern.size}, of route stop pattern #{rsp.onestop_id} occurs after stop #{rsp.stop_pattern[i-1]} but has a distance less than #{rsp.stop_pattern[i-1]}"
          rsp.distance_issues += 1
        end
      end
      # we'll be lenient if this difference is less than 5 meters.
      if (rsp.stop_distances[i] > geometry_length && (rsp.stop_distances[i] - geometry_length) > 5.0)
        puts "Distance issue: stop #{rsp.stop_pattern[i]}, number #{i+1}/#{rsp.stop_pattern.size}, of route stop pattern #{rsp.onestop_id} has a distance #{rsp.stop_distances[i]} greater than the length of the geometry, #{geometry_length}"
        rsp.distance_issues += 1
      end
    end
  end
end

class QualityCheck

  attr_accessor :issues, :feed_version, :changeset

  include GeometryQualityCheck

  def initialize(feed_version: nil, changeset: nil)
    @issues = []
    @feed_version = feed_version
    @changeset = changeset
  end

  def save
    # assumes entities are saved first
    Issue.import self.issues
    ewis = []
    self.issues.each do |issue|
      issue.entities_with_issues.each do |ewi|
        ewi.entity = OnestopId.find!(ewi.entity.onestop_id)
        ewi.issue = issue
      end
      ewis.concat issue.entities_with_issues
    end
    EntityWithIssues.import ewis
  end
end
