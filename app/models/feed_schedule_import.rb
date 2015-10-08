# == Schema Information
#
# Table name: feed_schedule_imports
#
#  id             :integer          not null, primary key
#  success        :boolean
#  import_log     :text
#  exception_log  :text
#  feed_import_id :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_feed_schedule_imports_on_feed_import_id  (feed_import_id)
#

class FeedScheduleImport < ActiveRecord::Base
  PER_PAGE = 1

  belongs_to :feed_import
  validates :feed_import, presence: true

  def failed(exception_log)
    # Mark as failed, bubble to parent feed_import
    self.update(
      success: false,
      exception_log: exception_log
    )
    self.feed_import.failed(exception_log)
  end

  def succeeded
    # Mark as succeeded, bubble to parent feed_import
    self.update(success: true)
    siblings = self.feed_import.feed_schedule_imports.pluck('success')
    if siblings.all?
      self.feed_import.succeeded
    end
  end
end
