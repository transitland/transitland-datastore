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
#  author_id  :integer
#
# Indexes
#
#  index_changesets_on_author_id  (author_id)
#

class ChangesetSerializer < ApplicationSerializer
  attributes :id,
             :notes,
             :applied,
             :applied_at,
             :created_at,
             :updated_at,
             :author_id,
             :change_payloads

  def change_payloads
    object.change_payloads.pluck(:id)
  end

end
