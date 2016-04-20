class QualityCheck

  def initialize()
    @issues = []
    @entities_with_issues = []
  end

  def outlier_stop(stop, rsp)
    if rsp.outlier_stop(stop[:geometry])
      issue = Issue.new
      issue.description = "Stop #{stop.onestop_id} is an outlier"
      @issues << issue
      @entities_with_issues << issue.entities_with_issues.new(entity: stop)
    end
  end

  def save
    Issue.import @issues
    @entities_with_issues.each do |ewi|

    end
    EntityWithIssues.import @entities_with_issues
  end
end
