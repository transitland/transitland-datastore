module GeometryQualityCheck
  # category
  def stop_rsp_distance(stop, rsp)
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
