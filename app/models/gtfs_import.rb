# == Schema Information
#
# Table name: gtfs_imports
#
#  id              :integer          not null, primary key
#  succeeded       :boolean
#  import_log      :text
#  exception_log   :text
#  import_level    :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  feed_version_id :integer          not null
#
# Indexes
#
#  index_gtfs_imports_on_feed_version_id  (feed_version_id)
#  index_gtfs_imports_on_succeeded        (succeeded)
#

class GTFSImport < ActiveRecord::Base
    belongs_to :feed_version
    has_one :feed, through: :feed_version, source_type: 'Feed'  
    validates :feed_version, presence: true
end
  
