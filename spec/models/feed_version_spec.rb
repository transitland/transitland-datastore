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
  let (:example_url) { 'https://developers.google.com/transit/gtfs/examples/sample-feed.zip' }
  let (:example_feed_path) { Rails.root.join('spec/support/example_gtfs_archives/example.zip').to_s }
  let (:example_sha1_raw) { "4e5e6a2668d12cca29c89a969d73e05e625d9596" }
  let (:example_sha1) { "068494206f0de49c8c831b5196026ce35911a4bb" }

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
      VCR.use_cassette('feed_fetch_example') do
        feed_version.fetch_and_normalize
      end
      expect(feed_version.sha1_raw).to eq example_sha1_raw
      expect(feed_version.fetched_at).to be_truthy
    end

    it 'normalizes feed' do
      feed_version = FeedVersion.new(url: example_url)
      VCR.use_cassette('feed_fetch_example') do
        feed_version.fetch_and_normalize
      end
      expect(feed_version.sha1).to eq example_sha1
      expect(feed_version.fetched_at).to be_truthy
    end

    it 'fails if files already exist' do
      feed_version = create(:feed_version_bart)
      expect { feed_version.fetch_and_normalize }.to raise_error(StandardError)
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
end
