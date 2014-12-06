# == Schema Information
#
# Table name: identifiers
#
#  id                     :integer          not null, primary key
#  identified_entity_id   :integer          not null
#  identified_entity_type :string(255)      not null
#  identifier             :string(255)
#  tags                   :hstore
#  created_at             :datetime
#  updated_at             :datetime
#
# Indexes
#
#  identified_entity                          (identified_entity_id,identified_entity_type)
#  index_identifiers_on_identified_entity_id  (identified_entity_id)
#

class IdentifierSerializer < ApplicationSerializer
  attributes :identifier,
             :tags,
             :created_at,
             :updated_at
end
