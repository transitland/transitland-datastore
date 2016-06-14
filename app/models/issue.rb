# == Schema Information
#
# Table name: issues
#
#  id                       :integer          not null, primary key
#  created_by_changeset_id  :integer          not null
#  resolved_by_changeset_id :integer
#  details                  :string
#  issue_type               :string
#  open                     :boolean          default(TRUE)
#  block_changeset_apply    :boolean          default(FALSE)
#  created_at               :datetime
#  updated_at               :datetime
#

class Issue < ActiveRecord::Base
  has_many :entities_with_issues
  belongs_to :feed_version
  belongs_to :created_by_changeset, class_name: 'Changeset'
  belongs_to :resolved_by_changeset, class_name: 'Changeset'

  def set_entity_with_issues_params(ewi_params)
    ewi_params[:entity] = OnestopId.find!(ewi_params.delete(:onestop_id))
    self.entities_with_issues << EntityWithIssues.find_or_initialize_by(ewi_params)
  end

  def changeset_from_entities
    entities_with_issues.map { |ewi| Changeset.find(Object.const_get(ewi.entity_type).find(ewi.entity_id).created_or_updated_in_changeset_id) }
                             .max_by { |changeset| changeset.updated_at }
  end

  # scope :find_by_equivalent, -> (issue) {
  #   joins(:entities_with_issues).where(created_by_changeset_id: issue.created_by_changeset_id,
  #                                         issue_type: issue.issue_type,
  #                                         "entities_with_issues.entity_id": issue.entities_with_issues.map(&:entity_id),
  #                                         "entities_with_issues.entity_type": issue.entities_with_issues.map(&:entity_type),
  #                                         "entities_with_issues.entity_attribute": issue.entities_with_issues.map(&:entity_attribute))
  # }

  def self.find_by_equivalent(issue)
    where(created_by_changeset_id: issue.created_by_changeset_id, issue_type: issue.issue_type, open: true).select { |existing|
      Set.new(existing.entities_with_issues.map(&:entity_id)) == Set.new(issue.entities_with_issues.map(&:entity_id)) &&
      Set.new(existing.entities_with_issues.map(&:entity_type)) == Set.new(issue.entities_with_issues.map(&:entity_type)) &&
      Set.new(existing.entities_with_issues.map(&:entity_attribute)) == Set.new(issue.entities_with_issues.map(&:entity_attribute))
    }.first
  end

end
