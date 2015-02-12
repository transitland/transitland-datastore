# == Schema Information
#
# Table name: identifiers
#
#  id                                 :integer          not null, primary key
#  identified_entity_id               :integer          not null
#  identified_entity_type             :string(255)      not null
#  identifier                         :string(255)
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  created_or_updated_in_changeset_id :integer
#  destroyed_in_changeset_id          :integer
#  version                            :integer
#  current                            :boolean
#
# Indexes
#
#  identified_entity                          (identified_entity_id,identified_entity_type)
#  identifiers_cu_in_changeset_id_index       (created_or_updated_in_changeset_id)
#  identifiers_d_in_changeset_id_index        (destroyed_in_changeset_id)
#  index_identifiers_on_current               (current)
#  index_identifiers_on_identified_entity_id  (identified_entity_id)
#

describe Identifier do
  context 'on a Stop' do
    it 'can be created' do
      identifier = create(:stop_identifier)
      expect(Identifier.exists?(identifier)).to be true
    end
  end

  context 'on an Operator' do
    it 'can be created' do
      identifier = create(:operator_identifier)
      expect(Identifier.exists?(identifier)).to be true
    end
  end
end
