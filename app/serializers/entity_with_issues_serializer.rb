# == Schema Information
#
# Table name: entities_with_issues
#
#  id               :integer          not null, primary key
#  entity_id        :integer
#  entity_type      :string
#  entity_attribute :string
#  issue_id         :integer
#  created_at       :datetime
#  updated_at       :datetime
#
# Indexes
#
#  index_entities_with_issues_on_entity_type_and_entity_id  (entity_type,entity_id)
#

class EntityWithIssuesSerializer < ApplicationSerializer
  attributes  :onestop_id,
              :id,
              :entity_type,
              :entity_attribute

  def onestop_id
    object.entity.try(:onestop_id)
  end
end
