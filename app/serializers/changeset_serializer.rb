# == Schema Information
#
# Table name: changesets
#
#  id         :integer          not null, primary key
#  notes      :text
#  applied    :boolean
#  applied_at :datetime
#  created_at :datetime
#  updated_at :datetime
#  user_id    :integer
#
# Indexes
#
#  index_changesets_on_user_id  (user_id)
#

class ChangesetSerializer < ApplicationSerializer
  attributes :id,
             :notes,
             :applied,
             :applied_at,
             :created_at,
             :updated_at,
             :change_payloads,
             :user

  def change_payloads
    object.change_payloads.pluck(:id)
  end

end
