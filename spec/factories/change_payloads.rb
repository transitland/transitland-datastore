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

# FactoryGirl.define do
#   factory :change_payload do
#     payload ""
# changeset nil
# action "MyString"
# type ""
#   end
#
# end
