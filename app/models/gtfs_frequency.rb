# == Schema Information
#
# Table name: gtfs_frequencies
#
#  id              :integer          not null, primary key
#  start_time      :integer          not null
#  end_time        :integer          not null
#  headway_secs    :integer          not null
#  exact_times     :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  feed_version_id :integer          not null
#  trip_id         :integer          not null
#
# Indexes
#
#  index_gtfs_frequencies_on_feed_version_id  (feed_version_id)
#  index_gtfs_frequencies_on_trip_id          (trip_id)
#

class GTFSFrequency < ActiveRecord::Base
  include GTFSEntity
  belongs_to :feed_version
  belongs_to :trip, class_name: 'GTFSTrip'
  validates :feed_version, presence: true, unless: :skip_association_validations
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :headway_secs, presence: true  
end
