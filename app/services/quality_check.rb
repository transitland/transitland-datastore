module StopQualityCheck
  def outlier_stop(stop, rsp, qc)
    if rsp.outlier_stop(stop[:geometry])
      issue = Issue.new
      issue.description = "Stop #{stop.onestop_id} is an outlier"
      issue.feed_version = qc.feed_version
      issue.entities_with_issues.new(entity: stop, issue: issue)
      issue.entities_with_issues.new(entity: rsp, issue: issue)
      qc.issues << issue
    end
  end
end

module RouteQualityCheck
end

module RouteStopPatternQualityCheck
end

class QualityCheck

  attr_accessor :issues, :feed_version, :changeset

  include StopQualityCheck

  def initialize(feed_version: nil, changeset: nil)
    @issues = []
    @feed_version = feed_version
    @changeset = changeset
  end
end
