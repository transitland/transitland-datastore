# == Schema Information
#
# Table name: stop_identifiers
#
#  id              :integer          not null, primary key
#  stop_id         :integer
#  identifier_type :string(255)
#  identifier      :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#
# Indexes
#
#  index_stop_identifiers_on_stop_id  (stop_id)
#

describe StopIdentifier do
  it 'can be created' do
    stop_identifier = create(:stop_identifier)
    expect(StopIdentifier.exists?(stop_identifier)).to be true
  end
end
