# == Schema Information
#
# Table name: changesets
#
#  id           :integer          not null, primary key
#  notes        :text
#  applied      :boolean
#  applied_at   :datetime
#  created_at   :datetime
#  updated_at   :datetime
#  author_email :string
#
# Indexes
#
#  index_changesets_on_author_email  (author_email)
#

class ChangesetSerializer < ApplicationSerializer
  attributes :id,
             :notes,
             :applied,
             :applied_at,
             :created_at,
             :updated_at,
             :change_payloads

  # TODO: include author_email when accessing with an API auth token

  def change_payloads
    object.change_payloads.pluck(:id)
  end

end
