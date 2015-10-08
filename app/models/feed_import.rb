# == Schema Information
#
# Table name: feed_imports
#
#  id                :integer          not null, primary key
#  feed_id           :integer
#  success           :boolean
#  sha1              :string
#  import_log        :text
#  validation_report :text
#  created_at        :datetime
#  updated_at        :datetime
#  exception_log     :text
#
# Indexes
#
#  index_feed_imports_on_created_at  (created_at)
#  index_feed_imports_on_feed_id     (feed_id)
#

class FeedImport < ActiveRecord::Base
  PER_PAGE = 1

  belongs_to :feed
  has_many :feed_schedule_imports, dependent: :destroy

  validates :feed, presence: true

  def failed(exception_log)
    self.update(
      success: false,
      exception_log: exception_log
    )
  end

  def succeeded
    self.update(success: true)
    t = Time.now
    self.feed.update(
      last_fetched_at: t,
      last_imported_at: t,
      last_sha1: self.sha1
    )
  end
end
