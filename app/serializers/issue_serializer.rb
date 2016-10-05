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

class IssueSerializer < ApplicationSerializer
  attributes :id,
             :created_by_changeset_id,
             :resolved_by_changeset_id,
             :imported_from_feed_onestop_id,
             :imported_from_feed_version_sha1,
             :details,
             :issue_type,
             :open,
             :created_at,
             :updated_at

  has_many :entities_with_issues

  def imported_from_feed_onestop_id
    object.created_by_changeset.imported_from_feed.try(:onestop_id)
  end

  def imported_from_feed_version_sha1
    object.created_by_changeset.imported_from_feed_version.try(:sha1)
  end
end
