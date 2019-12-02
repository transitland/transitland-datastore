# == Schema Information
#
# Table name: gtfs_feed_infos
#
#  id                  :integer          not null, primary key
#  feed_publisher_name :string           not null
#  feed_publisher_url  :string           not null
#  feed_lang           :string           not null
#  feed_start_date     :date
#  feed_end_date       :date
#  feed_version_name   :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  feed_version_id     :integer          not null
#
# Indexes
#
#  index_gtfs_feed_info_unique  (feed_version_id) UNIQUE
#

class GTFSFeedInfo < ActiveRecord::Base
  include GTFSEntity
  belongs_to :feed_version
  validates :feed_version, presence: true, unless: :skip_association_validations
  validates :feed_publisher_name, presence: true
  validates :feed_publisher_url, presence: true
  validates :feed_lang, presence: true
end
