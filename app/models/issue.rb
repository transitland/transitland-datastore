# == Schema Information
#
# Table name: issues
#
#  id                           :integer          not null, primary key
#  feed_version_id              :integer
#  created_by_changeset_id      :integer
#  resolved_by_changeset_id     :integer
#  description                  :string
#  block_import_changeset_apply :boolean          default(FALSE)
#  created_at                   :datetime
#  updated_at                   :datetime
#

class Issue < ActiveRecord::Base
  has_many :entities_with_issues
  has_many :entities, through: :entities_with_issues
  belongs_to :feed_version
  belongs_to :created_by_changeset, class_name: 'Changeset'
  belongs_to :resolved_by_changeset, class_name: 'Changeset'
end
