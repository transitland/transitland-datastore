# == Schema Information
#
# Table name: feed_versions
#
#  id                     :integer          not null, primary key
#  feed_id                :integer
#  feed_type              :string
#  file                   :string
#  earliest_calendar_date :date
#  latest_calendar_date   :date
#  sha1                   :string
#  md5                    :string
#  tags                   :hstore
#  fetched_at             :datetime
#  imported_at            :datetime
#  created_at             :datetime
#  updated_at             :datetime
#  import_level           :integer          default(0)
#  url                    :string
#  file_raw               :string
#  sha1_raw               :string
#  md5_raw                :string
#
# Indexes
#
#  index_feed_versions_on_feed_type_and_feed_id  (feed_type,feed_id)
#

describe FeedVersion do
  let (:example_url)              { 'http://localhost:8000/example.zip' }
  let (:example_sha1_raw)         { '2a7503435dcedeec8e61c2e705f6098e560e6bc6' }
  let (:example_sha1)             { '5edc7750991beda77e9f2fd7da2e3329253f199f' }
  let (:example_nested_flat)      { 'http://localhost:8000/example_nested.zip#example_nested/example' }
  let (:example_nested_zip)       { 'http://localhost:8000/example_nested.zip#example_nested/nested/example.zip' }
  let (:example_nested_sha1_raw)  { '65d278fdd3f5a9fae775a283ef6ca2cb7b961add' }
  let (:example_nested_sha1_flat) { '5edc7750991beda77e9f2fd7da2e3329253f199f' }
  let (:example_nested_sha1_zip)  { '5edc7750991beda77e9f2fd7da2e3329253f199f' }

  context '#compute_and_set_hashes' do
    it 'computes file hashes' do
      feed_version = create(:feed_version_bart)
      expect(feed_version.sha1).to eq '2d340d595ec566ba54b0a6a25359f71d94268b5c'
      expect(feed_version.md5).to eq '1197a60bab8f685492aa9e50a732b466'
    end
  end

  context '#read_gtfs_calendar_dates' do
    it 'reads earliest and latest dates from calendars.txt' do
      feed_version = create(:feed_version_bart)
      expect(feed_version.earliest_calendar_date).to eq Date.parse('2013-11-28')
      expect(feed_version.latest_calendar_date).to eq Date.parse('2017-01-01')
    end
  end

  context '#read_gtfs_feed_info' do
    it 'reads feed_info.txt and puts into tags' do
      feed_version = create(:feed_version_bart)
      expect(feed_version.tags['feed_lang']).to eq 'en'
      expect(feed_version.tags['feed_version']).to eq '36'
      expect(feed_version.tags['feed_publisher_url']).to eq 'http://www.bart.gov'
      expect(feed_version.tags['feed_publisher_name']).to eq 'Bay Area Rapid Transit'
    end
  end

  context '#fetch_and_normalize' do
    it 'downloads feed' do
      feed_version = FeedVersion.new(url: example_url)
      expect(feed_version.sha1).to be nil
      expect(feed_version.fetched_at).to be nil
      VCR.use_cassette('feed_fetch_example_local') do
        feed_version.fetch_and_normalize
      end
      expect(feed_version.sha1_raw).to eq example_sha1_raw
      expect(feed_version.fetched_at).to be_truthy
    end

    it 'normalizes feed' do
      feed_version = FeedVersion.new(url: example_url)
      VCR.use_cassette('feed_fetch_example_local') do
        feed_version.fetch_and_normalize
      end
      expect(feed_version.sha1).to eq example_sha1
      expect(feed_version.fetched_at).to be_truthy
    end

    it 'normalizes nested gtfs zip' do
      feed_version = FeedVersion.new(url: example_nested_zip)
      VCR.use_cassette('feed_fetch_nested') do
        feed_version.fetch_and_normalize
      end
      expect(feed_version.sha1).to eq example_nested_sha1_zip
      expect(feed_version.sha1_raw).to eq example_nested_sha1_raw
      expect(feed_version.fetched_at).to be_truthy
    end

    it 'normalizes nested gtfs flat' do
      feed_version = FeedVersion.new(url: example_nested_flat)
      VCR.use_cassette('feed_fetch_nested') do
        feed_version.fetch_and_normalize
      end
      expect(feed_version.sha1).to eq example_nested_sha1_flat
      expect(feed_version.sha1_raw).to eq example_nested_sha1_raw
      expect(feed_version.fetched_at).to be_truthy
    end

    it 'fails if files already exist' do
      feed_version = create(:feed_version_bart)
      VCR.use_cassette('feed_fetch_bart') do
        expect { feed_version.fetch_and_normalize }.to raise_error(StandardError)
      end
    end
  end

  context '#imported_schedule_stop_pairs' do
    before(:each) do
      @feed_version = create(:feed_version)
      @ssp = create(:schedule_stop_pair, feed: @feed_version.feed, feed_version: @feed_version)
    end

    it '#delete_schedule_stop_pairs' do
      @feed_version.delete_schedule_stop_pairs!
      expect(ScheduleStopPair.exists?(@ssp.id)).to be false
      expect(@feed_version.imported_schedule_stop_pairs.count).to eq(0)
    end
  end

  context '#is_active_feed_version' do
    it 'is active feed version' do
      feed = create(:feed)
      active_feed_version = create(:feed_version, feed: feed)
      inactive_feed_version = create(:feed_version, feed: feed)
      feed.update(active_feed_version: active_feed_version)
      expect(active_feed_version.is_active_feed_version).to eq true
      expect(inactive_feed_version.is_active_feed_version).to eq false
    end
  end

  context '#download_url' do
    it 'is included by default' do
      feed = create(:feed)
      feed_version = create(:feed_version, feed: feed)
      allow(feed_version).to receive_message_chain(:file, :url).and_return('http://cloudfront.com/file/f-9q9-bart.zip?auth=1')
      expect(feed_version.download_url).to eq('http://cloudfront.com/file/f-9q9-bart.zip')
    end

    it "isn't included for feeds that don't allow redistribution" do
      feed = create(:feed, license_redistribute: 'no')
      feed_version = create(:feed_version, feed: feed)
      allow(feed_version).to receive_message_chain(:file, :url).and_return('http://cloudfront.com/')
      expect(feed_version.download_url).to be_nil
    end
  end
end
