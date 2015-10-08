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

class FeedScheduleImportSerializer < ApplicationSerializer
  attributes :success,
             :import_log,
             :exception_log,
             :created_at,
             :updated_at
end
