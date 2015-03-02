# == Schema Information
#
# Table name: current_identifiers
#
#  id                                 :integer          not null, primary key
#  identified_entity_id               :integer          not null
#  identified_entity_type             :string           not null
#  identifier                         :string
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
end

class Identifier < BaseIdentifier
  self.table_name_prefix = 'current_'

  include CurrentTrackedByChangeset
  current_tracked_by_changeset kind_of_model_tracked: :relationship

  belongs_to :identified_entity, polymorphic: true

  def self.find_by_attributes(attrs = {})
    if attrs.keys.all?([:onestop_id, :identifier])
      identified_onestop_entity = OnestopIdService.find!(attrs[:identified_entity_onestop_id])
      find_by(identified_entity: identified_onestop_entity, identifier: attrs[:identifer])
    else
      raise ArgumentError.new('must specify Onestop ID for the identified entity and the identifier string')
    end
  end

  validates :identifier, presence: true, uniqueness: { scope: :identified_entity }
end

class OldIdentifier < BaseIdentifier
  include OldTrackedByChangeset

  belongs_to :identified_entity, polymorphic: true
end
