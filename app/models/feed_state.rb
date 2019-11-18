# == Schema Information
#
# Table name: feed_states
#
#  id                       :integer          not null, primary key
#  feed_id                  :integer          not null
#  feed_version_id          :integer
#  last_fetched_at          :datetime
#  last_successful_fetch_at :datetime
#  last_fetch_error         :string           default(""), not null
#  feed_realtime_enabled    :boolean          default(FALSE), not null
#  feed_priority            :integer
#  geometry                 :geography({:srid polygon, 4326
#  tags                     :json
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
# Indexes
#
#  index_feed_states_on_feed_id          (feed_id) UNIQUE
#  index_feed_states_on_feed_priority    (feed_priority) UNIQUE
#  index_feed_states_on_feed_version_id  (feed_version_id) UNIQUE
#

class FeedState < ActiveRecord::Base
end
