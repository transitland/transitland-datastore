describe IsAnEntityImportedFromFeeds do
  context '.where_import_level' do
    before(:each) do
      stops = []
      [1,2].each do |import_level|
        feed_version = create(:feed_version)
        feed_version.feed.activate_feed_version(feed_version.sha1, import_level)
        stop = create(:stop)
        stops << stop
        feed_version.entities_imported_from_feed.create!(entity: stop)
      end
      @stop1, @stop2 = stops
    end

    it 'matches single import_level' do
      expect(Stop.where_import_level(1)).to match_array([@stop1])
      expect(Stop.where_import_level(2)).to match_array([@stop2])
    end

    it 'excludes non matching' do
      expect(Stop.where_import_level(0)).to match_array([])
    end

    it 'allows multiple import_levels' do
      expect(Stop.where_import_level([1,2])).to match_array([@stop1, @stop2])
    end
  end
end
