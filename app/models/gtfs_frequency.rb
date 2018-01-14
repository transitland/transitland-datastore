# == Schema Information
#
# Table name: gtfs_frequencies
#
#  id              :integer          not null, primary key
#  start_time      :integer
#  end_time        :integer
#  headway_secs    :integer
#  exact_times     :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  feed_version_id :integer          not null
#  trip_id         :integer
#
# Indexes
#
#  index_gtfs_frequencies_on_end_time         (end_time)
#  index_gtfs_frequencies_on_feed_version_id  (feed_version_id)
#  index_gtfs_frequencies_on_headway_secs     (headway_secs)
#  index_gtfs_frequencies_on_start_time       (start_time)
#  index_gtfs_frequencies_on_trip_id          (trip_id)
#

class GTFSFrequency < ActiveRecord::Base
  belongs_to :feed_version
end
