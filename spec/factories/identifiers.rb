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
