# == Schema Information
#
# Table name: feeds
#
#  id                              :integer          not null, primary key
#  onestop_id                      :string
#  url                             :string
#  feed_format                     :string
#  tags                            :hstore
#  last_sha1                       :string
#  last_fetched_at                 :datetime
#  last_imported_at                :datetime
#  created_at                      :datetime
#  updated_at                      :datetime
#  license_name                    :string
#  license_url                     :string
#  license_use_without_attribution :string
#  license_create_derived_product  :string
#  license_redistribute            :string
#  operators_in_feed               :hstore           is an Array
#
# Indexes
#
#  index_feeds_on_onestop_id  (onestop_id)
#  index_feeds_on_tags        (tags)
#

describe Feed do
  context 'update_feeds_from_feed_registry' do
    it 'should pull latest Feed Registry' do
      allow(TransitlandClient::FeedRegistry).to receive(:repo) { true }
      allow(TransitlandClient::Entities::Feed).to receive(:all) { [] }
      Feed.update_feeds_from_feed_registry
      expect(TransitlandClient::FeedRegistry).to have_received(:repo)
    end
  end
end
