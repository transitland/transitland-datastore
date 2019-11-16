# == Schema Information
#
# Table name: feed_states
#
#  id                       :integer          not null, primary key
#  feed_id                  :integer          not null
#  feed_version_id          :integer
#  last_fetched_at          :datetime
#  last_successful_fetch_at :datetime
#  last_imported_at         :datetime
#  last_fetch_error         :string           default(""), not null
#  realtime_enabled         :boolean          default(FALSE), not null
#  priority                 :integer
#  geometry                 :geography({:srid polygon, 4326
#  tags                     :json
#  created_at               :datetime
#  updated_at               :datetime
#
# Indexes
#
#  index_feed_states_on_feed_id          (feed_id) UNIQUE
#  index_feed_states_on_feed_version_id  (feed_version_id) UNIQUE
#  index_feed_states_on_priority         (priority) UNIQUE
#

class FeedState < ActiveRecord::Base
end
