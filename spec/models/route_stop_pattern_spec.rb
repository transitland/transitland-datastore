# == Schema Information
#
# Table name: current_route_stop_patterns
#
#  id           :integer          not null, primary key
#  geometry     :geography({:srid geometry, 4326
#  tags         :hstore
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  route_id     :string
#  stop_pattern :string
#

require 'rails_helper'

RSpec.describe RouteStopPattern, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
