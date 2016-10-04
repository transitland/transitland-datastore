describe FeedMaintenanceService do
  before(:each) do
    @feed_version = create(:feed_version,
      earliest_calendar_date: '2016-01-01',
      latest_calendar_date: '2016-06-01'
    )
    @feed_version.feed.update!(active_feed_version: @feed_version)
  end

  context '.extend_expired_feed_version' do
    it 'extends a feed' do
      FeedMaintenanceService.extend_expired_feed_version(
        @feed_version,
        extend_from_date: '2016-05-01',
        extend_to_date: '2016-12-31'
      )
      @feed_version.reload
      expect(@feed_version.tags['extend_from_date']).to eq('2016-05-01')
      expect(@feed_version.tags['extend_to_date']).to eq('2016-12-31')
    end

    it 'defaults to -1 month, +1 year' do
      FeedMaintenanceService.extend_expired_feed_version(
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
      updated_at = @feed_version.reload.updated_at
      FeedMaintenanceService.extend_expired_feed_version(
        @feed_version
      )
      @feed_version.reload
      expect(@feed_version.tags['extend_to_date']).to eq('2016-07-01')
    end

    it 'creates an issue for the feed_version' do
      expect(EntityWithIssues.where(entity: @feed_version).count).to eq(0)
      FeedMaintenanceService.extend_expired_feed_version(
        @feed_version,
        extend_from_date: '2016-05-01',
        extend_to_date: '2016-12-31'
      )
      expect(EntityWithIssues.where(entity: @feed_version).count).to eq(1)
    end

  end

  context '.enqueue_next_feed_versions' do
    let(:date) { DateTime.now }
    let(:feed) { create(:feed) }

    it 'enqueues next_feed_version' do
      fv1 = create(:feed_version, feed: feed, earliest_calendar_date: date - 2.months)
      fv2 = create(:feed_version, feed: feed, earliest_calendar_date: date - 1.months)
      feed.update!(active_feed_version: fv1)
      expect {
        FeedMaintenanceService.enqueue_next_feed_versions(date)
      }.to change(FeedEaterWorker.jobs, :size).by(1)
    end

    it 'does not enqueue if no next_feed_version' do
      fv1 = create(:feed_version, feed: feed, earliest_calendar_date: date - 2.months)
      feed.update!(active_feed_version: fv1)
      expect {
        FeedMaintenanceService.enqueue_next_feed_versions(date)
      }.to change(FeedEaterWorker.jobs, :size).by(0)
    end

    it 'allows max_imports' do
      fv1 = create(:feed_version, feed: feed, earliest_calendar_date: date - 2.months)
      fv2 = create(:feed_version, feed: feed, earliest_calendar_date: date - 1.months)
      feed.update!(active_feed_version: fv1)
      expect {
        FeedMaintenanceService.enqueue_next_feed_versions(date, max_imports: 0)
      }.to change(FeedEaterWorker.jobs, :size).by(0)
    end

    it 'skips if manual_import tag is true' do
      fv1 = create(:feed_version, feed: feed, earliest_calendar_date: date - 2.months)
      fv2 = create(:feed_version, feed: feed, earliest_calendar_date: date - 1.months)
      feed.update!(active_feed_version: fv1, tags: {manual_import:"true"})
      expect {
        FeedMaintenanceService.enqueue_next_feed_versions(date)
      }.to change(FeedEaterWorker.jobs, :size).by(0)
    end

    it 'does not enqueue if next_feed_version has a feed_version_import attempt' do
      fv1 = create(:feed_version, feed: feed, earliest_calendar_date: date - 2.months)
      fv2 = create(:feed_version, feed: feed, earliest_calendar_date: date - 1.months)
      create(:feed_version_import, feed_version: fv2)
      feed.update!(active_feed_version: fv1)
      expect {
        FeedMaintenanceService.enqueue_next_feed_versions(date)
      }.to change(FeedEaterWorker.jobs, :size).by(0)
    end

    it 'creates an issue for the feed_version' do
      fv1 = create(:feed_version, feed: feed, earliest_calendar_date: date - 2.months)
      fv2 = create(:feed_version, feed: feed, earliest_calendar_date: date - 1.months)
      feed.update!(active_feed_version: fv1)
      expect(EntityWithIssues.where(entity: fv2).count).to eq(0)
      FeedMaintenanceService.enqueue_next_feed_versions(date)
      expect(EntityWithIssues.where(entity: fv2).count).to eq(1)
    end
  end
end
