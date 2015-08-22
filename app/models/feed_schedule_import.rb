# == Schema Information
#
# Table name: feed_schedule_imports
#
#  id                     :integer          not null, primary key
#  success                :boolean
#  import_log             :text
#  exception_log          :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  feed_version_import_id :integer
#
# Indexes
#
#  index_feed_schedule_imports_on_feed_version_import_id  (feed_version_import_id)
#

class FeedScheduleImport < ActiveRecord::Base
  PER_PAGE = 1

  belongs_to :feed_version_import
  has_one :feed, through: :feed_version_import

  validates :feed_version_import, presence: true

  def failed(exception_log)
    # Mark as failed, bubble to parent feed_version_import
    self.update(
      success: false,
      exception_log: exception_log
    )
    self.feed_version_import.failed(exception_log)
  end

  def succeeded
    # Mark as succeeded, bubble to parent feed_version_import
    self.update(success: true)
    siblings = self.feed_version_import.feed_schedule_imports.pluck('success')
    if siblings.all?
      self.feed_version_import.succeeded
    end
  end
end
