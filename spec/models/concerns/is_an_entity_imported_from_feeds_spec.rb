describe IsAnEntityImportedFromFeeds do
  before(:each) do
    stops = []
    @stop0 = create(:stop)
    @stop1 = create(:stop)
    @stop2 = create(:stop)
    @stop3 = create(:stop)
    # create feeds
    @feed = create(:feed)
    @fv1 = create(:feed_version, feed: @feed)
    @fv2 = create(:feed_version, feed: @feed)
    # add EIFFs; stop0 in fv1; stop1 in fv1, fv2; stop2 in fv2
    @fv1.entities_imported_from_feed.create!(entity: @stop0, feed: @feed)
    @fv1.entities_imported_from_feed.create!(entity: @stop1, feed: @feed)
    @fv2.entities_imported_from_feed.create!(entity: @stop1, feed: @feed)
    @fv2.entities_imported_from_feed.create!(entity: @stop2, feed: @feed)
    # activate
    @feed.activate_feed_version(@fv1.sha1, 1)
    @feed.activate_feed_version(@fv2.sha1, 2)
    # --> only stops referenced by @fv2 are active
    #     @stop1, @stop2 active
    #     @stop0, @stop3 inactive
  end

  context 'changeset' do
    it 'can add feed_version' do
      feed_version = create(:feed_version)
      stop = create(:stop, onestop_id: 's-9q9-test')
      gtfs_id = 'test'
      payload = {
        changes: [
          {
            action: "createUpdate",
            stop: {
              onestopId: stop.onestop_id,
              # sha1:gtfs_id
              # [sha1, gtfs_id]
              # { feed_version: sha1, gtfs_id: gtfs_id }
              # similar to includesOperators
              addFeedVersions: [{feedVersion: feed_version.sha1, gtfsId: gtfs_id}],
            }
          }
        ]
      }
      c = Changeset.create!(payload: payload)
      c.apply!
      expect(stop.reload.entities_imported_from_feed.find_by(feed_version: feed_version, gtfs_id: gtfs_id)).to be_truthy
    end

    it 'can remove feed_version' do
      feed_version = create(:feed_version)
      stop = create(:stop, onestop_id: 's-9q9-test')
      gtfs_id = 'test'
      stop.entities_imported_from_feed.create!(feed_version_id: feed_version.id, feed_id: feed_version.feed_id, gtfs_id: gtfs_id)
      payload = {
        changes: [
          {
            action: "createUpdate",
            stop: {
              onestopId: stop.onestop_id,
              removeFeedVersions: [{feedVersion: feed_version.sha1, gtfsId: gtfs_id}],
            }
          }
        ]
      }
      c = Changeset.create!(payload: payload)
      c.apply!
      expect(stop.reload.entities_imported_from_feed.find_by(feed_version: feed_version, gtfs_id: gtfs_id)).to be_falsy
    end
  end

  context '.where_import_level' do
    it 'matches single import_level' do
      expect(Stop.where_import_level(1)).to match_array([@stop0, @stop1])
      expect(Stop.where_import_level(2)).to match_array([@stop1, @stop2])
    end

    it 'excludes non matching' do
      expect(Stop.where_import_level(0)).to match_array([])
    end

    it 'allows multiple import_levels' do
      expect(Stop.where_import_level([1,2])).to match_array([@stop0, @stop1, @stop2])
    end

    it 'filters distinct' do
      expect(@stop1.imported_from_feed_versions.count).to eq(2)
      expect(@stop2.imported_from_feed_versions.count).to eq(1)
      expect(Stop.where_import_level(2)).to match_array([@stop1, @stop2])
    end
  end

  context '.where_imported_from_feed' do
    it 'returns entity imported from feed' do
      expect(Stop.where_imported_from_feed(@feed)).to match_array([@stop0, @stop1, @stop2])
    end

    it 'does not return entities from other feeds' do
      other_stop = create(:stop)
      feed_version = create(:feed_version)
      feed_version.entities_imported_from_feed.create!(entity: other_stop, feed: feed_version.feed)
      expect(Stop.where_imported_from_feed(feed_version.feed)).to match_array([other_stop])
    end

  end

  context '.where_imported_from_feed_version' do
    it 'returns entity imported from feed_version' do
      expect(Stop.where_imported_from_feed_version(@fv1)).to match_array([@stop0, @stop1])
      expect(Stop.where_imported_from_feed_version(@fv2)).to match_array([@stop1, @stop2])
    end
  end

  context '.where_imported_from_active_feed_version' do
    it 'finds entities referenced by active feed_version' do
      # see notes in before(:each)
      expect(Stop.where_imported_from_active_feed_version).to match_array([@stop1, @stop2])
    end
  end

  context '.where_not_imported_from_active_feed_version' do
    it 'finds entities not referenced by active feed_version' do
      # see notes in before(:each)
      expect(Stop.where_not_imported_from_active_feed_version).to match_array([@stop0, @stop3])
    end
  end

end
