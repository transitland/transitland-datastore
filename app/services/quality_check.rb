class QualityCheck
  attr_accessor :issues, :changeset

  def initialize(changeset: nil)
    @issues = []
    @changeset = changeset
  end

  def check
    raise NotImplementedError
  end
end

class QualityCheck::GeometryQualityCheck < QualityCheck

  LAST_STOP_DISTANCE_LENIENCY = 5.0 #meters

  # some aggregate stats on rsp distance calculation
  attr_accessor :distance_issues, :distance_issue_tests

  def distance_score
    if self.changeset.imported_from_feed
      import_score = ((self.distance_issue_tests - self.distance_issues).round(1)/self.distance_issue_tests).round(5) rescue 1.0
      log "Feed: #{self.changeset.imported_from_feed.onestop_id} imported with Valhalla Import Score: #{import_score} #{self.distance_issue_tests} Stop-RouteStopPattern pairs were tested and #{self.distance_issues} distance issues found."
    end
  end

  def check
    self.distance_issues = 0
    self.distance_issue_tests = 0

    import = !self.changeset.imported_from_feed.nil?
    distance_rsps = Set.new
    stop_rsp_gap_pairs =  Set.new

    self.changeset.route_stop_patterns_created_or_updated.each do |rsp|
      distance_rsps << rsp.onestop_id
      Stop.where(onestop_id: rsp.stop_pattern).each do |stop|
        stop_rsp_gap_pairs << [rsp.onestop_id, stop.onestop_id]
      end
      self.rsp_generated_from_stops(rsp)
      # other checks on rsp-exclusive attributes go here
    end

    self.changeset.stops_created_or_updated.each do |stop|
      unless import
        RouteStopPattern.where{ stop_pattern.within(stop.onestop_id) }.each do |rsp|
          distance_rsps << rsp.onestop_id
          stop_rsp_gap_pairs << [rsp.onestop_id, stop.onestop_id]
        end
      end
      if stop.geometry[:coordinates].eql?([0.0, 0.0])
        issue = Issue.new(created_by_changeset: self.changeset,
                          issue_type: 'stop_position_inaccurate',
                          details: "Stop #{stop.onestop_id} is serving null island.")
        issue.entities_with_issues.new(entity: stop, issue: issue, entity_attribute: 'geometry')
        self.issues << issue
      end
      # other checks on stop-exclusive attributes go here
    end

    distance_rsps.each do |onestop_id|
      rsp = RouteStopPattern.find_by_onestop_id!(onestop_id)
      # handle the case of 1 stop trips
      next if rsp.geometry[:coordinates].uniq.size == 1
      rsp.stop_pattern.each_index do |i|
        self.stop_distance(rsp, i)
      end
    end

    stop_rsp_gap_pairs.each do |rsp_onestop_id, stop_onestop_id|
      rsp = RouteStopPattern.find_by_onestop_id!(rsp_onestop_id)
      stop = Stop.find_by_onestop_id!(stop_onestop_id)
      # handle the case of 1 stop trips
      self.stop_rsp_distance_gap(stop, rsp) unless rsp.geometry[:coordinates].uniq.size == 1
    end

    self.distance_issue_tests = distance_rsps.map {|onestop_id| RouteStopPattern.find_by_onestop_id!(onestop_id).stop_pattern.size }.reduce(:+)
    self.distance_issues = Set.new(self.issues.select {|ewi| ['stop_rsp_distance_gap', 'distance_calculation_inaccurate'].include?(ewi.issue_type) }.each {|issue| issue.entities_with_issues.map(&:entity_id) }).size
    distance_score

    self.issues
  end

  def rsp_generated_from_stops(rsp)
    if rsp.stop_pattern.size == rsp.geometry[:coordinates].size
      if rsp.stop_pattern.map{ |onestop_id| Stop.find_by_onestop_id!(onestop_id).geometry[:coordinates] }.eql?(rsp.geometry[:coordinates])
        issue = Issue.new(created_by_changeset: self.changeset,
                          issue_type: 'rsp_line_inaccurate',
                          details: "RouteStopPattern #{rsp.onestop_id} has a line geometry generated from stops.")
        issue.entities_with_issues.new(entity: rsp, issue: issue, entity_attribute: 'geometry')
        self.issues << issue
      end
    end
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
          issue.entities_with_issues.new(entity: OnestopId.find!(rsp.stop_pattern[index-1]), issue: issue, entity_attribute: 'geometry')
          issue.entities_with_issues.new(entity: OnestopId.find!(rsp.stop_pattern[index]), issue: issue, entity_attribute: 'geometry')
          issue.entities_with_issues.new(entity: OnestopId.find!(rsp.stop_pattern[index+1]), issue: issue, entity_attribute: 'geometry') if index < rsp.stop_pattern.size - 1
          self.issues << issue
        end
      elsif (rsp.stop_distances[index-1] > rsp.stop_distances[index])
        issue = Issue.new(created_by_changeset: self.changeset,
                          issue_type: 'distance_calculation_inaccurate',
                          details: "Distance calculation inaccuracy. Stop #{rsp.stop_pattern[index]}, number #{index+1}/#{rsp.stop_pattern.size}, of route stop pattern #{rsp.onestop_id} occurs after stop #{rsp.stop_pattern[index-1]}, but has a distance less than #{rsp.stop_pattern[index-1]}")
        issue.entities_with_issues.new(entity: rsp, issue: issue, entity_attribute: 'stop_distances')
        issue.entities_with_issues.new(entity: OnestopId.find!(rsp.stop_pattern[index-2]), issue: issue, entity_attribute: 'geometry') unless index < 2
        issue.entities_with_issues.new(entity: OnestopId.find!(rsp.stop_pattern[index-1]), issue: issue, entity_attribute: 'geometry')
        issue.entities_with_issues.new(entity: OnestopId.find!(rsp.stop_pattern[index]), issue: issue, entity_attribute: 'geometry')
        self.issues << issue
      end
    end
    if ((rsp.stop_distances[index] - geometry_length) > LAST_STOP_DISTANCE_LENIENCY)
      issue = Issue.new(created_by_changeset: self.changeset,
                        issue_type: 'distance_calculation_inaccurate',
                        details: "Distance calculation inaccuracy. Stop #{rsp.stop_pattern[index]}, number #{index+1}/#{rsp.stop_pattern.size}, of route stop pattern #{rsp.onestop_id} has a distance #{rsp.stop_distances[index]}, greater than the length of the geometry, #{geometry_length}")
      issue.entities_with_issues.new(entity: rsp, issue: issue, entity_attribute: 'stop_distances')
      issue.entities_with_issues.new(entity: OnestopId.find!(rsp.stop_pattern[index-1]), issue: issue, entity_attribute: 'geometry') unless index < 1
      issue.entities_with_issues.new(entity: OnestopId.find!(rsp.stop_pattern[index]), issue: issue, entity_attribute: 'geometry')
      issue.entities_with_issues.new(entity: OnestopId.find!(rsp.stop_pattern[index+1]), issue: issue, entity_attribute: 'geometry') if index < rsp.stop_pattern.size - 1
      self.issues << issue
    end
  end
end
