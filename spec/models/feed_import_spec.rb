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

describe FeedImport do
  context 'succeed or fail' do
    it '#failed' do
      feed_import = create(:feed_import)
      feed_import.failed('error')
      expect(feed_import.success).to eq(false)
      expect(feed_import.exception_log).to eq('error')
    end

    it '#succeeded' do
      feed_import = create(:feed_import)
      feed_import.succeeded
      expect(feed_import.success).to eq(true)
    end

    it '#succeeded updates sha1 of parent feed' do
      feed_import = create(:feed_import)
      feed_import.succeeded
      expect(feed_import.sha1).to be_truthy
      expect(feed_import.feed.last_sha1).to eq(feed_import.sha1)
    end

    it '#succeeded updates last_imported_at / last_fetched_at of parent feed' do
      feed_import = create(:feed_import)
      feed_import.succeeded
      expect(feed_import.feed.last_fetched_at).to eq(feed_import.created_at)
      expect(feed_import.feed.last_imported_at).to eq(feed_import.updated_at)
    end
  end
end
