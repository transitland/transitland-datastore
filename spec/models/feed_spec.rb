# == Schema Information
#
# Table name: feeds
#
#  id               :integer          not null, primary key
#  url              :string(255)
#  feed_format      :string(255)
#  last_fetched_at  :datetime
#  last_imported_at :datetime
#  created_at       :datetime
#  updated_at       :datetime
#

describe Feed do
  it 'can be created' do
    feed = Feed.create(url: 'http://archives.sfmta.com/transitdata/google_transit.zip')
    expect(Feed.exists?(feed)).to be true
  end

  context 'fetch' do
    it 'should create a FeedImport' do
      VCR.use_cassette('feed_fetch_sfmta') do
        feed = Feed.create(url: 'http://archives.sfmta.com/transitdata/google_transit.zip')
        feed.fetch
        expect(FeedImport.count).to eq 1
        expect(feed.feed_imports.count).to eq 1
        expect(feed.feed_imports.first.file_fingerprint).to match /^[a-f0-9]{32}$/ # MD5 hash
        expect(feed.feed_imports.first.file.size).to be > 0
        expect(feed.feed_imports.first.feed_import_errors.count).to eq 0
        expect(feed.feed_imports.first.successful_fetch).to be true
        expect(feed.last_fetched_at).to be_within(1.minute).of(Time.now)
      end
    end

    it 'should create a FeedImportError when HTTP fails' do
      VCR.use_cassette('feed_fetch_sfmta_404') do
        feed = Feed.create(url: 'http://archives.sfmta.com/transitdata/google_transit.zipp')
        feed.fetch
        expect(FeedImport.count).to eq 1
        expect(FeedImportError.count).to eq 1
        expect(feed.feed_imports.first.successful_fetch).to be false
        expect(feed.feed_import_errors.first.error_type).to eq 'fetch'
      end
    end
  end
end
