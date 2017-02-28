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

  def self.categories
   {
     :route_geometry => ['stop_position_inaccurate', 'stop_rsp_distance_gap', 'rsp_line_only_stop_points', 'rsp_line_inaccurate', 'distance_calculation_inaccurate', 'rsp_stops_too_close'],
     :feed_fetch => ['feed_fetch_invalid_url', 'feed_fetch_invalid_source', 'feed_fetch_invalid_zip', 'feed_fetch_invalid_response'],
     :feed_import => ['feed_import_no_operators_found'],
     :station_hierarchy => ['stop_platform_parent_distance_gap', 'stop_platforms_too_close'],
     :uncategorized => ['route_color', 'stop_name', 'route_name', 'other', 'feed_version_maintenance_extend', 'feed_version_maintenance_import', 'missing_stop_conflation_result']
   }
  end

  extend Enumerize
  enumerize :issue_type, in: Issue.categories.values.flatten

  def self.issue_types_in_category(category)
    category = category.to_sym
    if self.categories.has_key?(category)
      return self.categories[category]
    else
      raise ArgumentError.new("unknown category #{category}")
    end
  end

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
