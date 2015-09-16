# == Schema Information
#
# Table name: current_operators_in_feed
#
#  id                                 :integer          not null, primary key
#  gtfs_agency_id                     :string
#  version                            :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#  operator_id                        :integer
#  feed_id                            :integer
#  created_or_updated_in_changeset_id :integer
#
# Indexes
#
#  current_oif                                     (created_or_updated_in_changeset_id)
#  index_current_operators_in_feed_on_feed_id      (feed_id)
#  index_current_operators_in_feed_on_operator_id  (operator_id)
#

class BaseOperatorInFeed < ActiveRecord::Base
  self.abstract_class = true
end

class OperatorInFeed < BaseOperatorInFeed
  self.table_name_prefix = 'current_'

  belongs_to :operator
  belongs_to :feed

  validates :operator, uniqueness: { scope: :feed }

  include CurrentTrackedByChangeset
  current_tracked_by_changeset kind_of_model_tracked: :relationship
  def self.find_by_attributes(attrs = {})
    if attrs.keys.include?(:feed_onestop_id) && attrs.keys.include?(:operator_onestop_id)
      feed = Route.find_by_onestop_id!(attrs[:feed_onestop_id])
      operator = Stop.find_by_onestop_id!(attrs[:operator_onestop_id])
      find_by(feed: feed, operator: operator)
    else
      raise ArgumentError.new('must specify Onestop IDs for an feed and for a operator')
    end
  end
  def before_destroy_making_history(changeset, old_model)
    if Operator.exists?(self.operator.id) && !self.operator.marked_for_destroy_making_history
      old_model.operator = self.operator
    elsif self.operator.old_model_left_after_destroy_making_history.present?
      old_model.operator = self.operator.old_model_left_after_destroy_making_history
    else
      raise 'about to create a broken OldOperatorInFeed record'
    end

    if Feed.exists?(self.feed.id) && !self.feed.marked_for_destroy_making_history
      old_model.feed = self.feed
    elsif self.feed.old_model_left_after_destroy_making_history.present?
      old_model.feed = self.feed.old_model_left_after_destroy_making_history
    else
      raise 'about to create a broken OldOperatorInFeed record'
    end
  end
end

class OldOperatorInFeed < BaseOperatorInFeed
  include OldTrackedByChangeset

  belongs_to :operator, polymorphic: true
  belongs_to :feed, polymorphic: true
end
