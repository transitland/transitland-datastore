# == Schema Information
#
# Table name: entities_imported_from_feed
#
#  id          :integer          not null, primary key
#  entity_id   :integer
#  entity_type :string
#  feed_id     :integer
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_entities_imported_from_feed_on_entity_type_and_entity_id  (entity_type,entity_id)
#  index_entities_imported_from_feed_on_feed_id                    (feed_id)
#

class EntityImportedFromFeed < ActiveRecord::Base
  belongs_to :entity, polymorphic: true
  belongs_to :feed
end
