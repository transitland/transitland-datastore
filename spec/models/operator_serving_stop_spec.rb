# == Schema Information
#
# Table name: operator_serving_stops
#
#  id          :integer          not null, primary key
#  stop_id     :integer          not null
#  operator_id :integer          not null
#  tags        :hstore
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_operator_serving_stops_on_operator_id              (operator_id)
#  index_operator_serving_stops_on_stop_id                  (stop_id)
#  index_operator_serving_stops_on_stop_id_and_operator_id  (stop_id,operator_id) UNIQUE
#

describe OperatorServingStop do
  it 'can be created' do
    operator_serving_stop = create(:operator_serving_stop)
    expect(OperatorServingStop.exists?(operator_serving_stop)).to be true
  end
end
