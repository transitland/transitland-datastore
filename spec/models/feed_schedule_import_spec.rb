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

require 'rails_helper'

RSpec.describe FeedScheduleImport, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
