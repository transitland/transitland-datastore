# == Schema Information
#
# Table name: feed_version_imports
#
#  id                :integer          not null, primary key
#  feed_version_id   :integer
#  created_at        :datetime
#  updated_at        :datetime
#  success           :boolean
#  import_log        :text
#  exception_log     :text
#  validation_report :text
#  import_level      :integer
#  operators_in_feed :json
#
# Indexes
#
#  index_feed_version_imports_on_feed_version_id  (feed_version_id)
#

class FeedVersionImport < ActiveRecord::Base
  belongs_to :feed_version
  has_one :feed, through: :feed_version, source_type: 'Feed'
  has_many :feed_schedule_imports, dependent: :destroy

  validates :feed_version, presence: true

  def failed(exception_log)
    self.update(
      success: false,
      exception_log: exception_log
    )
    self.feed_version.failed
  end

  def succeeded
    self.update(success: true)
    self.feed_version.succeeded(self.updated_at)
  end
end
