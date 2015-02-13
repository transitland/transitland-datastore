# == Schema Information
#
# Table name: changesets
#
#  id         :integer          not null, primary key
#  notes      :text
#  applied    :boolean
#  applied_at :datetime
#  payload    :json
#  created_at :datetime
#  updated_at :datetime
#

class ChangesetSerializer < ApplicationSerializer
  attributes :id,
             :notes,
             :applied,
             :applied_at,
             :payload,
             :created_at,
             :updated_at
end
