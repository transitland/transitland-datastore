# == Schema Information
#
# Table name: current_feeds
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string           not null
#  url                                :string
#  spec                               :string           default("gtfs"), not null
#  tags                               :hstore
#  last_fetched_at                    :datetime
#  last_imported_at                   :datetime
#  version                            :integer
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  created_or_updated_in_changeset_id :integer
#  geometry                           :geography({:srid geometry, 4326
#  active_feed_version_id             :integer
#  edited_attributes                  :string           default([]), is an Array
#  name                               :string
#  type                               :string
#  auth                               :jsonb            not null
#  urls                               :jsonb            not null
#  deleted_at                         :datetime
#  last_successful_fetch_at           :datetime
#  last_fetch_error                   :string           default(""), not null
#  license                            :jsonb            not null
#  other_ids                          :jsonb            not null
#  associated_feeds                   :jsonb            not null
#  languages                          :jsonb            not null
#  feed_namespace_id                  :string           default(""), not null
#  file                               :string           default(""), not null
#
# Indexes
#
#  index_current_feeds_on_active_feed_version_id              (active_feed_version_id)
#  index_current_feeds_on_auth                                (auth)
#  index_current_feeds_on_created_or_updated_in_changeset_id  (created_or_updated_in_changeset_id)
#  index_current_feeds_on_geometry                            (geometry) USING gist
#  index_current_feeds_on_onestop_id                          (onestop_id) UNIQUE
#  index_current_feeds_on_urls                                (urls)
#

require 'sidekiq/testing'

describe Feed do
  context 'changesets' do
    before(:each) do
      @changeset1 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            operator: {
              onestopId: 'o-9q9-caltrain',
              name: 'Caltrain',
              geometry: { type: "Polygon", coordinates:[[[-121.56649700000001,37.00360599999999],[-122.23195700000001,37.48541199999998],[-122.38653400000001,37.600005999999965],[-122.412018,37.63110599999998],[-122.39432299999996,37.77643899999997],[-121.65072100000002,37.12908099999998],[-121.61080899999999,37.085774999999984],[-121.56649700000001,37.00360599999999]]]}
            }
          },
          {
            action: 'createUpdate',
            feed: {
              onestopId: 'f-9q9-caltrain',
              url: 'http://www.caltrain.com/Assets/GTFS/caltrain/GTFS-Caltrain-Devs.zip',
              licenseUrl: 'http://www.caltrain.com/developer/Developer_License_Agreement_and_Privacy_Policy.html',
              licenseUseWithoutAttribution: 'yes',
              licenseCreateDerivedProduct: 'yes',
              licenseRedistribute: 'yes',
              includesOperators: [
                {
                  operatorOnestopId: 'o-9q9-caltrain',
                  gtfsAgencyId: 'caltrain-ca-us'
                }
              ],
              geometry: { type: "Polygon", coordinates:[[[-121.56649700000001,37.00360599999999],[-122.23195700000001,37.48541199999998],[-122.38653400000001,37.600005999999965],[-122.412018,37.63110599999998],[-122.39432299999996,37.77643899999997],[-121.65072100000002,37.12908099999998],[-121.61080899999999,37.085774999999984],[-121.56649700000001,37.00360599999999]]]}
            }
          }
        ]
      })
    end

    it 'can create a feed' do
      @changeset1.apply!
      expect(Operator.first.name).to eq "Caltrain"
      expect(Feed.first.url).to eq 'http://www.caltrain.com/Assets/GTFS/caltrain/GTFS-Caltrain-Devs.zip'
      expect(Feed.first.operators).to match_array([Operator.first])
      expect(@changeset1.feeds_created_or_updated).to match_array([Feed.first])
    end

    it 'can modify a feed, modifying model attributes' do
      changeset2 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            feed: {
              onestopId: 'f-9q9-caltrain',
              licenseRedistribute: 'no'
            }
          }
        ]
      })
      @changeset1.apply!
      changeset2.apply!
      expect(Feed.first.operators).to match_array([Operator.first])
      # expect(Feed.first.license_redistribute).to eq 'no'
      expect(changeset2.feeds_created_or_updated).to match_array([Feed.first])
    end

    it 'can modify a feed, adding another operator' do
      changeset2 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            operator: {
              onestopId: 'o-9q9-caltrain~dbtn',
              name: 'Caltrain Dumbarton',
              geometry: { type: "Polygon", coordinates:[[[-121.56649700000001,37.00360599999999],[-122.23195700000001,37.48541199999998],[-122.38653400000001,37.600005999999965],[-122.412018,37.63110599999998],[-122.39432299999996,37.77643899999997],[-121.65072100000002,37.12908099999998],[-121.61080899999999,37.085774999999984],[-121.56649700000001,37.00360599999999]]]}
            }
          },
          {
            action: 'createUpdate',
            feed: {
              onestopId: 'f-9q9-caltrain',
              includesOperators: [
                {
                  operatorOnestopId: 'o-9q9-caltrain~dbtn',
                  gtfsAgencyId: 'dumbarton'
                }
              ]
            }
          }
        ]
      })
      @changeset1.apply!
      changeset2.apply!
      expect(Feed.first.operators).to match_array([Operator.first, Operator.last])
      expect(Feed.first.operators_in_feed.map(&:gtfs_agency_id)).to match_array(['caltrain-ca-us', 'dumbarton'])
    end

    it 'can modify a feed, removing an operator relationship' do
      changeset2 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            feed: {
              onestopId: 'f-9q9-caltrain',
              doesNotIncludeOperators: [
                {
                  operatorOnestopId: 'o-9q9-caltrain',
                  gtfsAgencyId: 'caltrain-ca-us'
                }
              ]
            }
          }
        ]
      })
      @changeset1.apply!
      changeset2.apply!
      expect(Feed.first.operators).to match_array([])
      expect(Operator.first.feeds).to match_array([])
      expect(changeset2.operators_in_feed_destroyed).to match_array([OldOperatorInFeed.last])
    end

    it 'can delete a feed' do
      changeset2 = create(:changeset, payload: {
        changes: [
          {
            action: 'destroy',
            feed: {
              onestopId: 'f-9q9-caltrain'
            }
          }
        ]
      })
      @changeset1.apply!
      changeset2.apply!
      expect(Feed.count).to eq 0
      expect(Operator.count).to eq 1
      expect(OldFeed.count).to eq 1
      expect(OldFeed.first.old_operators_in_feed.first.operator).to eq Operator.first
      # TODO: figure out why this isn't working: expect(OldFeed.first.operators.first).to eq Operator.first
    end
  end

  it 'gets a bounding box around all its stops' do
    feed = build(:feed)
    stops = []
    stops << build(:stop, geometry: "POINT (-121.902181 37.329392)")
    stops << build(:stop, geometry: "POINT (-122.030742 37.378427)")
    stops << build(:stop, geometry: "POINT (-122.076327 37.393879)")
    stops << build(:stop, geometry: "POINT (-122.1649 37.44307)")
    feed.set_bounding_box_from_stops(stops)
    expect(feed.geometry(as: :geojson)).to eq({
      type: "Polygon",
      coordinates: [
        [
          [-122.1649, 37.329392],
          [-121.902181, 37.329392],
          [-121.902181, 37.44307],
          [-122.1649, 37.44307],
          [-122.1649, 37.329392]
        ]
      ]
    })
  end

  context '.feed_versions' do
    it 'orders by earliest_calendar_date' do
      feed = create(:feed)
      fv1 = create(:feed_version, feed: feed, earliest_calendar_date: '2015-01-01')
      fv2 = create(:feed_version, feed: feed, earliest_calendar_date: '2016-01-01')
      fv3 = create(:feed_version, feed: feed, earliest_calendar_date: '2017-01-01')
      feed.reload
      expect(feed.feed_versions).to match_array([fv3, fv2, fv1])
    end
  end

  context 'import status' do
    it 'handles never imported' do
      feed = create(:feed)
      expect(feed.import_status).to eq :never_imported
    end

    it 'handles most recent failed' do
      feed = create(:feed)
      create(:feed_version_import, feed: feed, success: true)
      create(:feed_version_import, feed: feed, success: false)
      expect(feed.import_status).to eq :most_recent_failed
    end

    it 'handles most recent succeeded' do
      feed = create(:feed)
      create(:feed_version_import, feed: feed, success: false)
      create(:feed_version_import, feed: feed, success: true)
      expect(feed.import_status).to eq :most_recent_succeeded
    end

    it 'handles in progress' do
      feed = create(:feed)
      create(:feed_version_import, feed: feed, success: true)
      create(:feed_version_import, feed: feed, success: false)
      create(:feed_version_import, feed: feed, success: nil)
      expect(feed.import_status).to eq :in_progress
    end
  end

  context '#activate_feed_version' do
    before(:each) do
      @feed = create(:feed)
      @fv1 = create(:feed_version, feed: @feed)
      @ssp1 = create(:schedule_stop_pair, feed: @feed, feed_version: @fv1)
    end

    it 'sets active_feed_version' do
      expect(@feed.active_feed_version).to be nil
      @feed.activate_feed_version(@fv1.sha1, 1)
      expect(@feed.active_feed_version).to eq(@fv1)
    end

    it 'sets active_feed_version import_level' do
      @feed.activate_feed_version(@fv1.sha1, 2)
      expect(@fv1.reload.import_level).to eq(2)
    end

    it 'requires associated feed_version' do
      fv3 = create(:feed_version)
      expect {
        @feed.deactivate_feed_version(fv3.sha1)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context '#deactivate_feed_version' do
    before(:each) do
      @feed = create(:feed)
      # feed versions
      @fv1 = create(:feed_version, feed: @feed)
      @ssp1 = create(:schedule_stop_pair, feed: @feed, feed_version: @fv1)
      @fv2 = create(:feed_version, feed: @feed)
      @ssp2 = create(:schedule_stop_pair, feed: @feed, feed_version: @fv2)
    end

    it 'deletes old feed version ssps' do
      # activate
      @feed.activate_feed_version(@fv1.sha1, 2)
      @feed.activate_feed_version(@fv2.sha1, 2)
      expect(@fv1.imported_schedule_stop_pairs.count).to eq(1)
      @feed.deactivate_feed_version(@fv1.sha1)
      expect(@fv1.imported_schedule_stop_pairs.count).to eq(0)
      expect(@feed.imported_schedule_stop_pairs.where_imported_from_active_feed_version).to match_array([@ssp2])
    end

    it 'cannot deactivate current active_feed_version' do

    end

    it 'requires associated feed_version' do
      fv3 = create(:feed_version)
      expect {
        @feed.deactivate_feed_version(fv3.sha1)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

  end

  context '.where_latest_fetch_exception' do
    let(:feed_succeed) { create(:feed) }
    let(:feed_failed) { create(:feed) }
    before(:each) do
      Issue.create!(issue_type: 'feed_fetch_invalid_source').entities_with_issues.create!(entity: feed_failed, entity_attribute: 'url')
    end

    it 'finds feeds with latest_fetch_exception_log' do
        expect(Feed.where_latest_fetch_exception(true)).to match_array([feed_failed])
    end

    it 'finds feeds without latest_fetch_exception_log' do
        expect(Feed.where_latest_fetch_exception(false)).to match_array([feed_succeed])
    end
  end

  context '.where_active_feed_version_import_level' do
    it 'finds active feed version with import_level' do
      fv1 = create(:feed_version, import_level: 2)
      feed1 = fv1.feed
      feed1.update!(active_feed_version: fv1)
      fv2 = create(:feed_version, import_level: 4)
      feed2 = fv2.feed
      feed2.update!(active_feed_version: fv2)
      expect(Feed.where_active_feed_version_import_level(0)).to match_array([])
      expect(Feed.where_active_feed_version_import_level(2)).to match_array([feed1])
      expect(Feed.where_active_feed_version_import_level(4)).to match_array([feed2])
    end

    it 'plays well with with_tag_equals' do
      feed = create(:feed, tags: {'test' => 'true'})
      fv1 = create(:feed_version, feed: feed)
      feed.activate_feed_version(fv1.sha1, 4)
      expect(Feed.where_active_feed_version_import_level(4).with_tag_equals('test', 'true')).to match_array([feed])
    end
  end

  context '.where_active_feed_version_valid' do
    before(:each) do
      date0 = Date.parse('2014-01-01')
      date1 = Date.parse('2015-01-01')
      date2 = Date.parse('2016-01-01')
      feed = create(:feed)
      fv1 = create(:feed_version, feed: feed, earliest_calendar_date: date0, latest_calendar_date: date1)
      fv2 = create(:feed_version, feed: feed, earliest_calendar_date: date1, latest_calendar_date: date2)
      feed.update(active_feed_version: fv2)
    end

    it 'finds valid active_feed_version' do
      expect(Feed.where_active_feed_version_valid('2015-06-01').count).to eq(1)
    end

    it 'expired active_feed_version' do
      expect(Feed.where_active_feed_version_valid('2016-06-01').count).to eq(0)
    end

    it 'active_feed_version that has not started' do
      expect(Feed.where_active_feed_version_valid('2014-06-01').count).to eq(0)
    end
  end

  context '.with_latest_feed_version_import' do
    before(:each) do
      @feed1 = create(:feed)
      @feed1_fv1 = create(:feed_version, feed: @feed1)
      @feed1_fvi1 = create(:feed_version_import, feed_version: @feed1_fv1, success: true, created_at: '2016-01-02')
    end

    it 'with_latest_feed_version_import' do
      expect(Feed.with_latest_feed_version_import.first.latest_feed_version_import_id).to eq(@feed1_fvi1.id)
    end
  end

  context '.where_latest_feed_version_import_status' do
    before(:each) do
      # Create several feeds with different #'s of FVs and FVIs

      # Last import: true
      @feed1 = create(:feed)
      @feed1_fv1 = create(:feed_version, feed: @feed1)
      create(:feed_version_import, feed_version: @feed1_fv1, success: false, created_at: '2016-01-01')
      create(:feed_version_import, feed_version: @feed1_fv1, success: true, created_at: '2016-01-02')

      # Last import: false
      @feed2 = create(:feed)
      @feed2_fv1 = create(:feed_version, feed: @feed2)
      create(:feed_version_import, feed_version: @feed2_fv1, success: true, created_at: '2016-01-01')
      create(:feed_version_import, feed_version: @feed2_fv1, success: true, created_at: '2016-01-02')
      @feed2_fv2 = create(:feed_version, feed: @feed2)
      create(:feed_version_import, feed_version: @feed2_fv2, success: false, created_at: '2016-01-02')
      create(:feed_version_import, feed_version: @feed2_fv2, success: false, created_at: '2016-01-03')
      # create(:feed_version_import, feed_version: @feed2_fv2, success: false, created_at: '2016-01-03')

      # Last import: nil
      @feed3 = create(:feed)
      @feed3_fv1 = create(:feed_version, feed: @feed3)
      create(:feed_version_import, feed_version: @feed3_fv1, success: nil, created_at: '2016-01-01')

      # Last import: does not exist
      @feed4 = create(:feed)
      @feed4_fv1 = create(:feed_version, feed: @feed4)
    end

    it 'finds successful import' do
      expect(Feed.where_latest_feed_version_import_status(true)).to match_array([@feed1])
    end

    it 'finds failed import' do
      expect(Feed.where_latest_feed_version_import_status(false)).to match_array([@feed2])
    end

    it 'finds in progress import' do
      expect(Feed.where_latest_feed_version_import_status(nil)).to match_array([@feed3])
    end

  end

  context '.where_newer_feed_version' do
    before(:each) do
      date0 = Date.parse('2014-01-01')
      date1 = Date.parse('2015-01-01')
      date2 = Date.parse('2016-01-01')
      # 3 feed versions, 2 newer
      @feed0 = create(:feed)
      fv0 = create(:feed_version, feed: @feed0, created_at: date0)
      fv1 = create(:feed_version, feed: @feed0, created_at: date1)
      fv2 = create(:feed_version, feed: @feed0, created_at: date2)
      @feed0.update!(active_feed_version: fv0)
      # 3 feed versions, 1 newer, 1 older
      @feed1 = create(:feed)
      fv3 = create(:feed_version, feed: @feed1, created_at: date0)
      fv4 = create(:feed_version, feed: @feed1, created_at: date1)
      fv5 = create(:feed_version, feed: @feed1, created_at: date2)
      @feed1.update!(active_feed_version: fv4)
      # 3 feed versions, 2 newer
      @feed2 = create(:feed)
      fv6 = create(:feed_version, feed: @feed2, created_at: date0)
      fv7 = create(:feed_version, feed: @feed2, created_at: date1)
      fv8 = create(:feed_version, feed: @feed2, created_at: date2)
      @feed2.update!(active_feed_version: fv8)
      # 1 feed version, current
      @feed3 = create(:feed)
      fv9 = create(:feed_version, feed: @feed3, created_at: date0)
      @feed3.update!(active_feed_version: fv9)
    end

    it 'finds superseded feeds' do
      expect(Feed.where_active_feed_version_update).to match_array([@feed0, @feed1])
    end
  end

  context '.feed_version_update_statistics' do
    before(:each) do
      @url = 'http://example.com/example.zip'
      @feed = create(:feed)
      @d = Date.parse('2015-01-01')
      @fv1 = create(:feed_version, feed: @feed, url: @url, sha1: 'a', fetched_at: @d-30.day, earliest_calendar_date: @d-30.day, latest_calendar_date: @d-15.day)
      @fv2 = create(:feed_version, feed: @feed, url: @url, sha1: 'b', fetched_at: @d-15.day, earliest_calendar_date: @d-20.day, latest_calendar_date: @d)
      @fv3 = create(:feed_version, feed: @feed, url: @url, sha1: 'c', fetched_at: @d, earliest_calendar_date: @d-5.day, latest_calendar_date: @d+15.day)
      @fv4 = create(:feed_version, feed: @feed, url: @url, sha1: 'd', fetched_at: @d+15.day, earliest_calendar_date: @d+10.day, latest_calendar_date: @d+30.day)
    end

    it 'generates fetched_at frequency' do
      pmf = Feed.feed_version_update_statistics(@feed)
      expect(pmf[:feed_versions_total]).to eq(4)
      expect(pmf[:feed_versions_filtered]).to eq(4)
      expect(pmf[:feed_versions_filtered_sha1].size).to eq(4)
      expect(pmf[:feed_versions_filtered_sha1]).to match_array(["a", "b", "c", "d"])
      expect(pmf[:fetched_at_frequency]).to eq(15)
      expect(pmf[:scheduled_service_overlap_average]).to eq(5.0)
      expect(pmf[:scheduled_service_duration_average]).to eq(18.75)
    end

    it 'excludes url is empty' do
      @fv5 = create(:feed_version, feed: @feed, url: "", sha1: 'e', fetched_at: @d+20.day, earliest_calendar_date: @d+15.day, latest_calendar_date: @d+60.day)
      pmf = Feed.feed_version_update_statistics(@feed)
      expect(pmf[:feed_versions_total]).to eq(5)
      expect(pmf[:feed_versions_filtered]).to eq(4)
      expect(pmf[:feed_versions_filtered_sha1].size).to eq(4)
    end

    it 'works with 0 feed versions' do
      FeedVersion.delete_all
      pmf = Feed.feed_version_update_statistics(@feed)
      expect(pmf[:feed_versions_total]).to eq(0)
      expect(pmf[:feed_version_transitions]).to be_nil
      expect(pmf[:fetched_at_frequency]).to be_nil
      expect(pmf[:scheduled_service_overlap_average]).to be_nil
      expect(pmf[:scheduled_service_duration_average]).to be_nil
    end

    it 'works with 1 feed versions' do
      FeedVersion.where('id not in (?)', @fv1.id).delete_all
      pmf = Feed.feed_version_update_statistics(@feed)
      expect(pmf[:feed_versions_total]).to eq(1)
      expect(pmf[:scheduled_service_duration_average]).to eq(15.0)
      expect(pmf[:scheduled_service_overlap_average]).to be_nil
      expect(pmf[:feed_version_transitions]).to be_nil
      expect(pmf[:fetched_at_frequency]).to be_nil
    end
  end

  context '#import_policy' do
    it 'sets default import_policy' do
      feed = create(:feed)
      expect(feed.import_policy).to be_nil
    end

    it 'sets only allowed values' do
      feed = create(:feed)
      expect{feed.import_policy = 'asdf'}.to raise_error
    end

    it 'sets import_policy' do
      feed = create(:feed)
      feed.import_policy = 'immediately'
      expect(feed.import_policy).to eq('immediately')
    end
  end

  context '#status' do
    it 'sets default status' do
      feed = create(:feed)
      expect(feed.status).to eq 'active'
    end

    it 'sets only allowed values' do
      feed = create(:feed)
      expect{feed.status = 'asdf'}.to raise_error
    end

    it 'sets status' do
      feed = create(:feed)
      feed.status = 'replaced'
      expect(feed.status).to eq('replaced')
    end
  end

  context 'GTFSRealtimeFeed' do
    before(:each) do
      @changeset1 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            operator: {
              onestopId: 'o-9q9-caltrain',
              name: 'Caltrain',
              geometry: { type: "Polygon", coordinates:[[[-121.56649700000001,37.00360599999999],[-122.23195700000001,37.48541199999998],[-122.38653400000001,37.600005999999965],[-122.412018,37.63110599999998],[-122.39432299999996,37.77643899999997],[-121.65072100000002,37.12908099999998],[-121.61080899999999,37.085774999999984],[-121.56649700000001,37.00360599999999]]]}
            }
          },
          {
            action: 'createUpdate',
            gtfsRealtimeFeed: {
              onestopId: 'f-debug',
              urls: {
                'realtime_alerts': 'http://example.com/test.zip',
              },
              licenseUrl: 'http://www.caltrain.com/developer/Developer_License_Agreement_and_Privacy_Policy.html',
              licenseUseWithoutAttribution: 'yes',
              licenseCreateDerivedProduct: 'yes',
              licenseRedistribute: 'yes',
              includesOperators: [
                {
                  operatorOnestopId: 'o-9q9-caltrain',
                  gtfsAgencyId: 'caltrain-ca-us'
                }
              ],
              geometry: { type: "Polygon", coordinates:[[[-121.56649700000001,37.00360599999999],[-122.23195700000001,37.48541199999998],[-122.38653400000001,37.600005999999965],[-122.412018,37.63110599999998],[-122.39432299999996,37.77643899999997],[-121.65072100000002,37.12908099999998],[-121.61080899999999,37.085774999999984],[-121.56649700000001,37.00360599999999]]]}
            }
          }
        ]
      })
    end

    it 'can be created from a changeset' do
      osid = 'f-debug'
      url = 'http://example.com/test.zip'
      @changeset1.apply!
      a = Feed.find_by_onestop_id(osid)
      expect(a.type).to eq('GTFSRealtimeFeed')
      expect(a.urls['realtime_alerts']).to eq(url)
    end
    
    it 'accepts valid url types' do
      changeset2 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            gtfsRealtimeFeed: {
              onestopId: 'f-debug',
              urls: {
                'realtime_vehicle_positions': "http://example.com/"
              }
            }
          }
        ]
      })
      @changeset1.apply!
      changeset2.apply!
    end
  end
end
