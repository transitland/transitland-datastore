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
#
# Indexes
#
#  index_feed_versions_on_feed_type_and_feed_id  (feed_type,feed_id)
#

describe FeedVersion do
  it 'computes file hashes' do
    feed_version = create(:feed_version_bart)
    expect(feed_version.sha1).to eq '2d340d595ec566ba54b0a6a25359f71d94268b5c'
    expect(feed_version.md5).to eq '1197a60bab8f685492aa9e50a732b466'
  end

  it 'reads earliest and latest dates from calendars.txt' do
    feed_version = create(:feed_version_bart)
    expect(feed_version.earliest_calendar_date).to eq Date.parse('2013-11-28')
    expect(feed_version.latest_calendar_date).to eq Date.parse('2017-01-01')
  end

  it 'reads feed_info.txt and puts into tags' do
    feed_version = create(:feed_version_bart)
    expect(feed_version.tags['feed_lang']).to eq 'en'
    expect(feed_version.tags['feed_version']).to eq '36'
    expect(feed_version.tags['feed_publisher_url']).to eq 'http://www.bart.gov'
    expect(feed_version.tags['feed_publisher_name']).to eq 'Bay Area Rapid Transit'
  end

  context 'imported_schedule_stop_pairs' do
    before(:each) do
      @feed_version = create(:feed_version)
      @ssp = create(:schedule_stop_pair, feed: @feed_version.feed, feed_version: @feed_version)
    end

    it '#activate_schedule_stop_pairs' do
      expect(@ssp.active).to be nil
      @feed_version.activate_schedule_stop_pairs!
      expect(@ssp.reload.active).to be true
    end

    it '#deactivate_schedule_stop_pairs' do
      @ssp.update(active: true)
      expect(@ssp.active).to be true
      @feed_version.deactivate_schedule_stop_pairs!
      expect(@ssp.reload.active).to be false
    end

    it '#delete_schedule_stop_pairs' do
      @feed_version.delete_schedule_stop_pairs!
      expect(ScheduleStopPair.exists?(@ssp.id)).to be false
      expect(@feed_version.imported_schedule_stop_pairs.count).to eq(0)
    end

  end

end
