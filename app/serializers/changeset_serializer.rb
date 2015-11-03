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
#

class ChangesetSerializer < ApplicationSerializer
  cache key: 'changesets', expires_in: 1.week

  attributes :id,
             :notes,
             :applied,
             :applied_at,
             :created_at,
             :updated_at,
             :payload

  def payload
    # TODO: move change payloads to a nested endpoint, so they can be paginated.
    {changes: object.change_payloads.map {|x| x.payload_as_ruby_hash[:changes]}}
  end

end
