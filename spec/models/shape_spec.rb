# == Schema Information
#
# Table name: current_shapes
#
#  id         :integer          not null, primary key
#  geometry   :geography({:srid geometry, 4326
#  tags       :hstore
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe Shape, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
