# == Schema Information
#
# Table name: stops
#
#  id         :integer          not null, primary key
#  onestop_id :string(255)
#  geometry   :spatial          geometry, 4326
#  tags       :hstore
#  created_at :datetime
#  updated_at :datetime
#  name       :string(255)
#
# Indexes
#
#  index_stops_on_onestop_id  (onestop_id)
#

describe Stop do
  it 'can be created' do
    stop = create(:stop)
    expect(Stop.exists?(stop)).to be true
  end
end
