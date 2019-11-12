# == Schema Information
#
# Table name: feed_versions
#
#  id                     :integer          not null, primary key
#  feed_id                :integer          not null
#  feed_type              :string           default("gtfs"), not null
#  file                   :string           default(""), not null
#  earliest_calendar_date :date             not null
#  latest_calendar_date   :date             not null
#  sha1                   :string           not null
#  md5                    :string
#  tags                   :hstore
#  fetched_at             :datetime         not null
#  imported_at            :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  import_level           :integer          default(0), not null
#  url                    :string           default(""), not null
#  file_raw               :string
#  sha1_raw               :string
#  md5_raw                :string
#  file_feedvalidator     :string
#  deleted_at             :datetime
#  sha1_dir               :string
#
# Indexes
#
#  index_feed_versions_on_earliest_calendar_date  (earliest_calendar_date)
#  index_feed_versions_on_feed_type_and_feed_id   (feed_type,feed_id)
#  index_feed_versions_on_latest_calendar_date    (latest_calendar_date)
#

describe FeedVersion do
  context 'calendar scopes' do
    before(:each) do
      @fv1 = create(:feed_version, earliest_calendar_date: '2016-01-01', latest_calendar_date: '2017-01-01')
      @fv2 = create(:feed_version, earliest_calendar_date: '2016-02-01', latest_calendar_date: '2017-02-01')
      @fv3 = create(:feed_version, earliest_calendar_date: '2016-03-01', latest_calendar_date: '2017-03-01')
    end

    context '.where_calendar_coverage_begins_at_or_before' do
      it 'finds FeedVersions with coverage before a date' do
        expect(FeedVersion.where_calendar_coverage_begins_at_or_before('2016-04-15')).to match_array([@fv1, @fv2, @fv3])
      end
      it 'finds FeedVersions with coverage on or before a date' do
        expect(FeedVersion.where_calendar_coverage_begins_at_or_before('2016-02-01')).to match_array([@fv1, @fv2])
      end
      it 'finds FeedVersions with coverage on a date' do
        expect(FeedVersion.where_calendar_coverage_begins_at_or_before('2016-01-01')).to match_array([@fv1])
      end
    end

    context '.where_calendar_coverage_begins_at_or_after' do
      it 'finds FeedVersions with coverage after a date' do
        expect(FeedVersion.where_calendar_coverage_begins_at_or_after('2015-12-01')).to match_array([@fv1, @fv2, @fv3])
      end
      it 'finds FeedVersions with coverage on or after a date' do
        expect(FeedVersion.where_calendar_coverage_begins_at_or_after('2016-02-01')).to match_array([@fv2, @fv3])
      end
      it 'finds FeedVersions with coverage on a date' do
        expect(FeedVersion.where_calendar_coverage_begins_at_or_after('2016-03-01')).to match_array([@fv3])
      end
    end

    context '.where_calendar_coverage_includes' do
      it 'finds FeedVersions with coverage including a date' do
        expect(FeedVersion.where_calendar_coverage_includes('2016-04-01')).to match_array([@fv1, @fv2, @fv3])
      end
      it 'finds FeedVersions with coverage including, inclusive' do
        expect(FeedVersion.where_calendar_coverage_includes('2016-02-01')).to match_array([@fv1, @fv2])
      end
      it 'excludes FeedVersions outside coverage range' do
        expect(FeedVersion.where_calendar_coverage_includes('2017-01-15')).to match_array([@fv2, @fv3])
      end
    end
  end

  context '#compute_and_set_hashes' do
    it 'computes file hashes' do
      feed_version = create(:feed_version_bart)
      expect(feed_version.sha1).to eq '2d340d595ec566ba54b0a6a25359f71d94268b5c'
      expect(feed_version.md5).to eq '1197a60bab8f685492aa9e50a732b466'
    end
  end

  context '#delete_schedule_stop_pairs' do
    before(:each) do
      @feed_version = create(:feed_version)
      @ssp = create(:schedule_stop_pair, feed: @feed_version.feed, feed_version: @feed_version)
    end

    it 'deletes ssps' do
      @feed_version.delete_schedule_stop_pairs!
      expect(ScheduleStopPair.exists?(@ssp.id)).to be false
      expect(@feed_version.imported_schedule_stop_pairs.count).to eq(0)
    end
  end

  context '#extend_schedule_stop_pairs_service_end_date' do
    before(:each) do
      @feed_version = create(:feed_version)
      @extend_from = Date.parse('2016-01-01')
      @extend_to = Date.parse('2017-01-01')
      @ssp1 = create(:schedule_stop_pair, feed: @feed_version.feed, feed_version: @feed_version, service_end_date: @extend_from)
      @ssp2 = create(:schedule_stop_pair, feed: @feed_version.feed, feed_version: @feed_version, service_end_date: @extend_from - 1.day)
    end

    it 'extends ssp service_end_date' do
      @feed_version.extend_schedule_stop_pairs_service_end_date(@extend_from, @extend_to)
      expect(@ssp1.reload.service_end_date).to eq(@extend_to)
    end

    it 'does not extend before extend_from' do
      service_end_date = @ssp2.service_end_date
      @feed_version.extend_schedule_stop_pairs_service_end_date(@extend_from, @extend_to)
      expect(@ssp2.reload.service_end_date).to eq(service_end_date)
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

  context '#import_status' do
    it 'never_imported' do
      feed_version = create(:feed_version)
      expect(feed_version.import_status).to eq(:never_imported)
    end

    it 'in_progress' do
      feed_version = create(:feed_version)
      create(:feed_version_import, success: true, feed_version: feed_version)
      create(:feed_version_import, success: nil, feed_version: feed_version)
      expect(feed_version.import_status).to eq(:in_progress)
    end

    it 'most_recent_failed' do
      feed_version = create(:feed_version)
      create(:feed_version_import, success: true, feed_version: feed_version)
      create(:feed_version_import, success: false, feed_version: feed_version)
      expect(feed_version.import_status).to eq(:most_recent_failed)
    end

    it 'most_recent_succeeded' do
      feed_version = create(:feed_version)
      create(:feed_version_import, success: false, feed_version: feed_version)
      create(:feed_version_import, success: true, feed_version: feed_version)
      expect(feed_version.import_status).to eq(:most_recent_succeeded)
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
