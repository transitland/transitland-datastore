# == Schema Information
#
# Table name: change_payloads
#
#  id           :integer          not null, primary key
#  payload      :json
#  changeset_id :integer
#  action       :string
#  type         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_change_payloads_on_changeset_id  (changeset_id)
#

# require 'rails_helper'

RSpec.describe ChangePayload, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
