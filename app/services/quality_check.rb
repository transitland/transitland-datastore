class QualityCheck
  attr_accessor :issues, :changeset

  def initialize(changeset: nil)
    @issues = []
    @changeset = changeset
  end

  def check
    raise NotImplementedError
  end

  # def find_issue(issue)
  #   @issues.detect{ |existing| issue.compare(existing) }
  # end
end

class GeometryQualityCheck < QualityCheck

  LAST_STOP_DISTANCE_LENIENCY = 5.0 #meters

  # some aggregate stats on rsp distance calculation
  attr_accessor :distance_issues, :distance_issue_tests

  def check
    self.distance_issues = 0
    self.distance_issue_tests = 0

    distance_rsps = Set.new
    stop_rsp_gap_pairs =  Set.new

    # TODO if changeset is from import, we should go ahead and assign all rsps to distance_rsps

    self.changeset.route_stop_patterns_created_or_updated.each do |rsp|
      distance_rsps << rsp
      rsp.stop_pattern.map { |onestop_id| OnestopId.find!(onestop_id) }.each do |stop|
        stop_rsp_gap_pairs << [rsp, stop]
      end
      # other checks on rsp go here
    end

    self.changeset.stops_created_or_updated.each do |stop|
        RouteStopPattern.where{ stop_pattern.within(stop.onestop_id) }.each do |rsp|
          distance_rsps << rsp
          stop_rsp_gap_pairs << [rsp, stop]
        end
        # other checks on stop go here
    end

    distance_rsps.each do |rsp|
      rsp.stop_pattern.each_index do |i|
        self.stop_distance(rsp, i)
      end
    end

    stop_rsp_gap_pairs.each do |rsp, stop|
      self.stop_rsp_distance_gap(stop, rsp)
    end


    self.distance_issue_tests = distance_rsps.map {|rsp| rsp.stop_pattern.size }.reduce(:+)
    self.distance_issues = Set.new(self.issues.select {|ewi| ['stop_rsp_distance_gap', 'distance_calculation_inaccurate'].include?(ewi.issue_type) }.each {|issue| issue.entities_with_issues.map(&:entity_id) }).size

    self.issues
  end

  def stop_rsp_distance_gap(stop, rsp)
    if rsp.outlier_stop(stop[:geometry])
      issue = Issue.new(created_by_changeset: self.changeset,
                        issue_type: 'stop_rsp_distance_gap',
                        details: "Stop #{stop.onestop_id} and RouteStopPattern #{rsp.onestop_id} too far apart.")
      issue.entities_with_issues.new(entity: stop, issue: issue, entity_attribute: 'geometry')
      issue.entities_with_issues.new(entity: rsp, issue: issue, entity_attribute: 'geometry')
      self.issues << issue
    end
  end

  def stop_distance(rsp, index)
    geometry_length = rsp[:geometry].length
    if (index != 0)
      if (rsp.stop_distances[index-1] == rsp.stop_distances[index])
        unless rsp.stop_pattern[index].eql? rsp.stop_pattern[index-1]
          issue = Issue.new(created_by_changeset: self.changeset,
                            issue_type: 'distance_calculation_inaccurate',
                            details: "Distance calculation inaccuracy. Stop #{rsp.stop_pattern[index]}, number #{index+1}/#{rsp.stop_pattern.size}, of route stop pattern #{rsp.onestop_id} has the same distance as #{rsp.stop_pattern[index-1]}.")
          issue.entities_with_issues.new(entity: rsp, issue: issue, entity_attribute: 'stop_distances')
          self.issues << issue
        end
      elsif (rsp.stop_distances[index-1] > rsp.stop_distances[index])
        issue = Issue.new(created_by_changeset: self.changeset,
                          issue_type: 'distance_calculation_inaccurate',
                          details: "Distance calculation inaccuracy. Stop #{rsp.stop_pattern[index]}, number #{index+1}/#{rsp.stop_pattern.size}, of route stop pattern #{rsp.onestop_id} occurs after stop #{rsp.stop_pattern[index-1]}, but has a distance less than #{rsp.stop_pattern[index-1]}")
        issue.entities_with_issues.new(entity: rsp, issue: issue, entity_attribute: 'stop_distances')
        self.issues << issue
      end
    end
    if ((rsp.stop_distances[index] - geometry_length) > LAST_STOP_DISTANCE_LENIENCY)
      issue = Issue.new(created_by_changeset: self.changeset,
                        issue_type: 'distance_calculation_inaccurate',
                        details: "Distance calculation inaccuracy. Stop #{rsp.stop_pattern[index]}, number #{index+1}/#{rsp.stop_pattern.size}, of route stop pattern #{rsp.onestop_id} has a distance #{rsp.stop_distances[index]}, greater than the length of the geometry, #{geometry_length}")
      issue.entities_with_issues.new(entity: rsp, issue: issue, entity_attribute: 'stop_distances')
      self.issues << issue
    end
  end
end
