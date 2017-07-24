
# == Schema Information
#
# Table name: feed_version_infos
#
#  id              :integer          not null, primary key
#  type            :string
#  data            :json
#  feed_version_id :integer
#  created_at      :datetime
#  updated_at      :datetime
#
# Indexes
#
#  index_feed_version_infos_on_feed_version_id           (feed_version_id)
#  index_feed_version_infos_on_feed_version_id_and_type  (feed_version_id,type) UNIQUE
#

describe FeedVersionInfo do
  it 'one type per FeedVersion' do
    fv = create(:feed_version)
    create(:feed_version_info, feed_version: fv, type: 'FeedVersionInfoStatistics')
    create(:feed_version_info, feed_version: fv, type: 'FeedVersionInfoConveyalValidation')
    expect {
      create(:feed_version_info, feed_version: fv, type: 'FeedVersionInfoStatistics')
    }.to raise_error(ActiveRecord::RecordInvalid)
  end

  context '.where_feed' do
    it 'returns matches by feed' do
      fv1 = create(:feed_version)
      fv2 = create(:feed_version)
      fv3 = create(:feed_version)
      fvi1 = create(:feed_version_info, feed_version: fv1)
      fvi2 = create(:feed_version_info, feed_version: fv2)
      expect(FeedVersionInfo.where_feed(fv1.feed)).to match_array(fvi1)
      expect(FeedVersionInfo.where_feed([fv1.feed, fv2.feed])).to contain_exactly(fvi1, fvi2)
      expect(FeedVersionInfo.where_feed([fv3.feed])).to contain_exactly()
    end
  end

  context '.where_type' do
    it 'returns by type' do
      fvi1 = create(:feed_version_info_conveyal_validation)
      fvi2 = create(:feed_version_info_statistics)
      expect(FeedVersionInfo.where_type('FeedVersionInfoConveyalValidation')).to contain_exactly(fvi1)
      expect(FeedVersionInfo.where_type(['FeedVersionInfoConveyalValidation', 'FeedVersionInfoStatistics'])).to contain_exactly(fvi1, fvi2)
    end
  end
end
