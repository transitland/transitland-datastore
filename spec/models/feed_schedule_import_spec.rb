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

describe FeedScheduleImport do
  context 'succeed or fail' do
    it '#failed' do
      feed_schedule_import = create(:feed_schedule_import)
      feed_schedule_import.failed('error')
      expect(feed_schedule_import.success).to eq(false)
      expect(feed_schedule_import.exception_log).to eq('error')
    end

    it '#failed updates parent FeedImport' do
      feed_schedule_import = create(:feed_schedule_import)
      feed_schedule_import.failed('error')
      expect(feed_schedule_import.feed_import.success).to eq(false)
    end

    it '#succeeded' do
      feed_schedule_import = create(:feed_schedule_import)
      feed_schedule_import.succeeded
      expect(feed_schedule_import.success).to eq(true)
    end

    it '#succeeded updates parent FeedImport' do
      feed_schedule_import = create(:feed_schedule_import)
      feed_schedule_import.succeeded
      expect(feed_schedule_import.feed_import.success).to eq(true)
    end

    it '#succeeded updates parent FeedImport only if all siblings succeed' do
      feed_schedule_import = create(:feed_schedule_import)
      feed_schedule_import2 = create(:feed_schedule_import, feed_import: feed_schedule_import.feed_import)
      feed_schedule_import.succeeded
      expect(feed_schedule_import.feed_import.success).to_not eq(true)
      feed_schedule_import2.succeeded
      expect(feed_schedule_import.feed_import.success).to eq(true)
    end

    it '#succeeded does not update parent FeedImport if any sibling fails' do
      feed_schedule_import = create(:feed_schedule_import)
      feed_schedule_import2 = create(:feed_schedule_import, feed_import: feed_schedule_import.feed_import)
      feed_schedule_import2.failed('error')
      feed_schedule_import.succeeded
      expect(feed_schedule_import.feed_import.success).to_not eq(true)
    end

  end
end
