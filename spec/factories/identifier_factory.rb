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

FactoryGirl.define do
  factory :stop_identifier, class: Identifier do
    association :identified_entity, factory: :stop
    identifier { ['19th Avenue & Holloway St', '390'].sample }
  end

  factory :operator_identifier, class: Identifier do
    association :identified_entity, factory: :operator
    identifier { ['SFMTA', 'BART'].sample }
  end
end
