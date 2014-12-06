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
