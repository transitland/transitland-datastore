# == Schema Information
#
# Table name: stops
#
#  id         :integer          not null, primary key
#  onestop_id :string(255)
#  geometry   :spatial          geometry, 4326
#  codes      :string(255)      is an Array
#  names      :string(255)      is an Array
#  tags       :hstore
#  created_at :datetime
#  updated_at :datetime
#

describe Stop do
  it 'can be created' do
    stop = create(:stop)
    expect(Stop.exists?(stop)).to be true
  end
end
