class QualityCheck
  attr_accessor :issues, :changeset

  def initialize(changeset: nil)
    @issues = []
    @changeset = changeset
  end

  def check
    raise NotImplementedError
  end

  def find_issue(issue)
  end
end

class GeometryQualityCheck < QualityCheck

  LAST_STOP_DISTANCE_LENIENCY = 5.0

  attr_accessor :distance_issues, :distance_issue_tests

  def check
    stop_rsp_distance_gap_checked = false
    self.distance_issues = 0
    self.distance_issue_tests = 0

    self.changeset.route_stop_patterns_created_or_updated.each do |rsp|
      rsp_stops = rsp.stop_pattern.map { |onestop_id| OnestopId.find!(onestop_id) }
      rsp_stops.each do |stop|
        self.stop_rsp_distance_gap(stop, rsp)
      end
      stop_rsp_distance_gap_checked = true
      self.stop_distances(rsp)
    end

    self.changeset.stops_created_or_updated.each do |stop|
      if !stop_rsp_distance_gap_checked
        stop_rsps = RouteStopPattern.where{ stop_pattern.within(stop.onestop_id) }
        stop_rsps.each do |rsp|
          self.stop_rsp_distance_gap(stop, rsp)
        end
      end
    end
    self.issues
  end

  def stop_rsp_distance_gap(stop, rsp)
    self.distance_issue_tests += 1
    if rsp.outlier_stop(stop[:geometry])
      issue = Issue.new(created_by_changeset: self.changeset,
                        issue_type: 'stop_rsp_distance_gap',
                        details: "Stop #{stop.onestop_id} and RouteStopPattern #{rsp.onestop_id} too far apart")
      issue.entities_with_issues.new(entity: stop, issue: issue, entity_attribute: 'geometry')
      issue.entities_with_issues.new(entity: rsp, issue: issue, entity_attribute: 'geometry')
      self.issues << issue
      self.distance_issues += 1
    end
  end

  def stop_distances(rsp)
    geometry_length = rsp[:geometry].length
    rsp.stop_distances.each_index do |i|
      if (i != 0)
        if (rsp.stop_distances[i-1] == rsp.stop_distances[i])
          unless rsp.stop_pattern[i].eql? rsp.stop_pattern[i-1]
            issue = Issue.new(created_by_changeset: self.changeset,
                              issue_type: 'distance',
                              details: "Stop #{rsp.stop_pattern[i]}, number #{i+1}/#{rsp.stop_pattern.size},
                                       of route stop pattern #{rsp.onestop_id} has the same distance as #{rsp.stop_pattern[i-1]},
                                       which may indicate a segment matching issue or outlier stop.")
            issue.entities_with_issues.new(entity: rsp, issue: issue, entity_attribute: 'stop_distances')
            self.issues << issue
          end
        elsif (rsp.stop_distances[i-1] > rsp.stop_distances[i])
          issue = Issue.new(created_by_changeset: self.changeset,
                            issue_type: 'distance',
                            details: "Stop #{rsp.stop_pattern[i]}, number #{i+1}/#{rsp.stop_pattern.size},
                                     of route stop pattern #{rsp.onestop_id} occurs after stop #{rsp.stop_pattern[i-1]},
                                     but has a distance less than #{rsp.stop_pattern[i-1]}")
          issue.entities_with_issues.new(entity: rsp, issue: issue, entity_attribute: 'stop_distances')
          self.issues << issue
        end
      end
      if (rsp.stop_distances[i] > geometry_length && (rsp.stop_distances[i] - geometry_length) > LAST_STOP_DISTANCE_LENIENCY)
        issue = Issue.new(created_by_changeset: self.changeset,
                          issue_type: 'distance',
                          details: "Stop #{rsp.stop_pattern[i]}, number #{i+1}/#{rsp.stop_pattern.size},
                                   of route stop pattern #{rsp.onestop_id} has a distance #{rsp.stop_distances[i]},
                                   greater than the length of the geometry, #{geometry_length}")
        issue.entities_with_issues.new(entity: rsp, issue: issue, entity_attribute: 'stop_distances')
        self.issues << issue
      end
    end
  end
end
