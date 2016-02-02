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
             :user,
             :feed_onestop_id,
             :feed_version_sha1

  def user
    object.user.id if object.user
  end

  def change_payloads
    object.change_payloads.pluck(:id)
  end

  def feed_onestop_id
    object.feed.try(:onestop_id)
  end

  def feed_version_sha1
    object.feed_version.try(:sha1)
  end

end
