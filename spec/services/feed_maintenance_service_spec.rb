describe FeedMaintenanceService do
  before(:each) do
    @feed_version = create(:feed_version,
      earliest_calendar_date: '2016-01-01',
      latest_calendar_date: '2016-06-01'
    )
    @feed_version.feed.update!(active_feed_version: @feed_version)
  end

  context '.extend_feed_version' do
    it 'extends a feed' do
      FeedMaintenanceService.extend_feed_version(
        @feed_version,
        extend_from_date: '2016-05-01',
        extend_to_date: '2016-12-31'
      )
      @feed_version.reload
      expect(@feed_version.tags['extend_from_date']).to eq('2016-05-01')
      expect(@feed_version.tags['extend_to_date']).to eq('2016-12-31')
    end

    it 'defaults to -1 month, +1 year' do
      FeedMaintenanceService.extend_feed_version(
        @feed_version
      )
      @feed_version.reload
      expect(@feed_version.tags['extend_from_date']).to eq('2016-05-01')
      expect(@feed_version.tags['extend_to_date']).to eq('2017-06-01')
    end

    it 'skips previously extended feed_versions' do
      @feed_version.tags ||= {}
      @feed_version.tags['extend_from_date'] = '2016-05-01'
      @feed_version.tags['extend_to_date'] = '2016-07-01'
      @feed_version.save!
      updated_at = @feed_version.updated_at
      FeedMaintenanceService.extend_feed_version(
        @feed_version
      )
      @feed_version.reload
      expect(@feed_version.updated_at).to eq(updated_at)
    end

  end
end
