# == Schema Information
#
# Table name: issues
#
#  id                       :integer          not null, primary key
#  created_by_changeset_id  :integer
#  resolved_by_changeset_id :integer
#  details                  :string
#  issue_type               :string
#  open                     :boolean          default(TRUE)
#  created_at               :datetime
#  updated_at               :datetime
#

class Issue < ActiveRecord::Base
  has_many :entities_with_issues, dependent: :delete_all
  belongs_to :created_by_changeset, class_name: 'Changeset'
  belongs_to :resolved_by_changeset, class_name: 'Changeset'

  scope :with_type, -> (search_string) { where(issue_type: search_string.split(',')) }
  scope :from_feed, -> (feed_onestop_id) {
    where("issues.id IN (SELECT entities_with_issues.issue_id FROM entities_with_issues INNER JOIN
    entities_imported_from_feed ON entities_with_issues.entity_id=entities_imported_from_feed.entity_id
    AND entities_with_issues.entity_type=entities_imported_from_feed.entity_type WHERE entities_imported_from_feed.feed_id=?)
    OR issues.id in (SELECT issues.id FROM issues INNER JOIN changesets ON
    issues.created_by_changeset_id=changesets.id WHERE changesets.feed_id=?)",
    Feed.find_by_onestop_id!(feed_onestop_id), Feed.find_by_onestop_id!(feed_onestop_id))
  }

  extend Enumerize
  enumerize :issue_type,
            in: ['stop_position_inaccurate',
                 'stop_rsp_distance_gap',
                 'distance_calculation_inaccurate',
                 'rsp_line_inaccurate',
                 'route_color',
                 'stop_name',
                 'route_name',
                 'feed_fetch_error',
                 'feed_version_maintenance_extend',
                 'feed_version_maintenance_import',
                 'uncategorized']

  def equivalent?(issue)
    self.issue_type == issue.issue_type &&
    Set.new(self.entities_with_issues.map(&:entity_id)) == Set.new(issue.entities_with_issues.map(&:entity_id)) &&
    Set.new(self.entities_with_issues.map(&:entity_type)) == Set.new(issue.entities_with_issues.map(&:entity_type)) &&
    Set.new(self.entities_with_issues.map(&:entity_attribute)) == Set.new(issue.entities_with_issues.map(&:entity_attribute))
  end

  def deprecate
    log("Deprecating issue: #{self.as_json(include: [:entities_with_issues])}")
    self.destroy
  end

  def self.find_by_equivalent(issue)
    where(created_by_changeset_id: issue.created_by_changeset_id, issue_type: issue.issue_type, open: true).detect { |existing|
      Set.new(existing.entities_with_issues.map(&:entity_id)) == Set.new(issue.entities_with_issues.map(&:entity_id)) &&
      Set.new(existing.entities_with_issues.map(&:entity_type)) == Set.new(issue.entities_with_issues.map(&:entity_type)) &&
      Set.new(existing.entities_with_issues.map(&:entity_attribute)) == Set.new(issue.entities_with_issues.map(&:entity_attribute))
    }
  end

  def self.issues_of_entity(entity, entity_attributes: [])
    issues = Issue.joins(:entities_with_issues).where(entities_with_issues: { entity: entity })
    issues = issues.where("entity_attribute IN (?)", entity_attributes) unless entity_attributes.empty?
    return issues
  end
end
