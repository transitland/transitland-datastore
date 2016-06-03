class EntityWithIssuesSerializer < ApplicationSerializer
  attributes  :id,
              :onestop_id,
              :entity_attribute

  def onestop_id
    object.entity.onestop_id
  end
end
