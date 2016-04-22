class QualityCheck

  attr_accessor :creator_changeset

  def initialize(feed_version: nil, changeset: nil)
    @issue_entities = Hash.new { |h,k| h[k] = [] }
    @feed_version = feed_version
    @creator_changeset = changeset
  end

  def outlier_stop(stop, rsp)
    if rsp.outlier_stop(stop[:geometry])
      issue = Issue.new
      issue.feed_version = @feed_version
      issue.description = "Stop #{stop.onestop_id} is an outlier"
      @issue_entities[issue] = issue.entities_with_issues.new(entity: stop)
    end
  end

  def save
    @issue_entities.keys.each { |issue| issue.created_by_changeset = @creator_changeset }
    Issue.import @issue_entities.keys
    @issue_entities.each do |issue, ewi|
      ewi.issue = issue
      ewi.entity = ewi.entity_type.constantize.find_by_onestop_id!(ewi.entity.onestop_id)
    end
    EntityWithIssues.import @issue_entities.values
  end
end
