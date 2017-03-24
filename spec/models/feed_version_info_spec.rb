
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
    expect {
      create(:feed_version_info, feed_version: fv, type: 'FeedVersionInfoStatistics')
    }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
