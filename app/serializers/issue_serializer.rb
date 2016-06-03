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
             :resolved_by_changeset_id,
             :details,
             :issue_type,
             :block_changeset_apply,
             :open,
             :created_at,
             :updated_at

  has_many :entities_with_issues
end
