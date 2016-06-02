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

class IssueSerializer < ApplicationSerializer
  attributes :id,
             :created_by_changeset_id,
             :entities_with_issues,
             :details,
             :issue_type,
             :open

  def entities_with_issues
    object.entities_with_issues.map { |e| Object.const_get(e.entity_type).find(e.entity_id).onestop_id }
  end
end
