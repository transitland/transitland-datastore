# == Schema Information
#
# Table name: current_identifiers
#
#  id                                 :integer          not null, primary key
#  identified_entity_id               :integer          not null
#  identified_entity_type             :string(255)      not null
#  identifier                         :string(255)
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#
# Indexes
#
#  #c_identifiers_cu_in_changeset_id_index            (created_or_updated_in_changeset_id)
#  identified_entity                                  (identified_entity_id,identified_entity_type)
#  index_current_identifiers_on_identified_entity_id  (identified_entity_id)
#

class BaseIdentifier < ActiveRecord::Base
  self.abstract_class = true

  belongs_to :identified_entity, polymorphic: true
end

class Identifier < BaseIdentifier
  self.table_name_prefix = 'current_'

  include CurrentTrackedByChangeset

  validates :identifier, presence: true, uniqueness: { scope: :identified_entity }
end

class OldIdentifier < BaseIdentifier
  include OldTrackedByChangeset
end
