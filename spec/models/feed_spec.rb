# == Schema Information
#
# Table name: current_feeds
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  url                                :string
#  feed_format                        :string
#  tags                               :hstore
#  last_sha1                          :string
#  last_fetched_at                    :datetime
#  last_imported_at                   :datetime
#  license_name                       :string
#  license_url                        :string
#  license_use_without_attribution    :string
#  license_create_derived_product     :string
#  license_redistribute               :string
#  version                            :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#  created_or_updated_in_changeset_id :integer
#  geometry                           :geography({:srid geometry, 4326
#
# Indexes
#
#  index_current_feeds_on_created_or_updated_in_changeset_id  (created_or_updated_in_changeset_id)
#


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
              identifiers: ['usntd://9134'],
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
              ]
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
      expect(Feed.first.license_redistribute).to eq 'no'
      expect(changeset2.feeds_created_or_updated).to match_array([Feed.first])
    end

    it 'can modify a feed, modifying a GTFS agency ID' do
      changeset2 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            feed: {
              onestopId: 'f-9q9-caltrain',
              includesOperators: [
                {
                  operatorOnestopId: 'o-9q9-caltrain',
                  gtfsAgencyId: 'new-id'
                }
              ]
            }
          }
        ]
      })
      @changeset1.apply!
      changeset2.apply!
      expect(Feed.first.operators).to match_array([Operator.first])
      expect(Feed.first.operators_in_feed.first.gtfs_agency_id).to eq 'new-id'
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
                  operatorOnestopId: 'o-9q9-caltrain'
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
    feed = create(:feed_caltrain)
    allow(feed).to receive(:file_path) { 'spec/support/example_gtfs_archives/f-9q9-caltrain.zip' }
    feed.set_bounding_box_from_gtfs_stops
    expect(feed.geometry).to eq({
      type: 'Polygon',
      coordinates: [
        [
          [
            -122.412076,
            37.003485
          ],
          [
            -121.566088,
            37.003485
          ],
          [
            -121.566088,
            37.776439
          ],
          [
            -122.412076,
            37.776439
          ],
          [
            -122.412076,
            37.003485
          ]
        ]
      ]
    })
  end
end
