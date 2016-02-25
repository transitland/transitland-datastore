# == Schema Information
#
# Table name: changesets
#
#  id              :integer          not null, primary key
#  notes           :text
#  applied         :boolean
#  applied_at      :datetime
#  created_at      :datetime
#  updated_at      :datetime
#  user_id         :integer
#  feed_id         :integer
#  feed_version_id :integer
#
# Indexes
#
#  index_changesets_on_feed_id          (feed_id)
#  index_changesets_on_feed_version_id  (feed_version_id)
#  index_changesets_on_user_id          (user_id)
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
             :imported_from_feed_onestop_id,
             :imported_from_feed_version_sha1,
             :feeds_created_or_updated,
             :feeds_destroyed,
             :stops_created_or_updated,
             :stops_destroyed,
             :operators_created_or_updated,
             :operators_destroyed,
             :routes_created_or_updated,
             :routes_destroyed

  def user
    object.user.id if object.user
  end

  def change_payloads
    # NOTE: this is an n+1 query, but it let's
    # us skip loading ChangePayload's into memory.
    object.change_payloads.pluck(:id)
  end

  def imported_from_feed_onestop_id
    object.imported_from_feed.try(:onestop_id)
  end

  def imported_from_feed_version_sha1
    object.imported_from_feed_version.try(:sha1)
  end

  def feeds_created_or_updated
    object.feeds_created_or_updated.map(&:onestop_id)
  end

  def feeds_destroyed
    object.feeds_destroyed.map(&:onestop_id)
  end

  def stops_created_or_updated
    object.stops_created_or_updated.map(&:onestop_id)
  end

  def stops_destroyed
    object.stops_destroyed.map(&:onestop_id)
  end

  def operators_created_or_updated
    object.operators_created_or_updated.map(&:onestop_id)
  end

  def operators_destroyed
    object.operators_destroyed.map(&:onestop_id)
  end

  def routes_created_or_updated
    object.routes_created_or_updated.map(&:onestop_id)
  end

  def routes_destroyed
    object.routes_destroyed.map(&:onestop_id)
  end
end
