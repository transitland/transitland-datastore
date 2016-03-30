describe IsAnEntityImportedFromFeeds do
  context '.where_import_level' do
    before(:each) do
      stops = []
      @stop1 = create(:stop)
      @stop2 = create(:stop)
      # create feeds
      feed = create(:feed)
      fv1 = create(:feed_version, feed: feed)
      fv2 = create(:feed_version, feed: feed)
      # add EIFFs; stop1 in fv1, fv2; stop2 in fv2
      fv1.entities_imported_from_feed.create!(entity: @stop1)
      fv2.entities_imported_from_feed.create!(entity: @stop1)
      fv2.entities_imported_from_feed.create!(entity: @stop2)
      # activate
      feed.activate_feed_version(fv1.sha1, 1)
      feed.activate_feed_version(fv2.sha1, 2)
    end

    it 'matches single import_level' do
      expect(Stop.where_import_level(1)).to match_array([@stop1])
      expect(Stop.where_import_level(2)).to match_array([@stop1, @stop2])
    end

    it 'chains with where_active' do
    end

    it 'excludes non matching' do
      expect(Stop.where_import_level(0)).to match_array([])
    end

    it 'allows multiple import_levels' do
      expect(Stop.where_import_level([1,2])).to match_array([@stop1, @stop2])
    end

    it 'filters distinct' do
      expect(@stop1.imported_from_feed_versions.count).to eq(2)
      expect(@stop2.imported_from_feed_versions.count).to eq(1)
      expect(Stop.where_import_level([2])).to match_array([@stop1, @stop2])
    end

  end
end
