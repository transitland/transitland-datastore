# == Schema Information
#
# Table name: feed_version_gtfs_imports
#
#  id              :integer          not null, primary key
#  success         :boolean          not null
#  import_log      :text             not null
#  exception_log   :text             not null
#  import_level    :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  feed_version_id :integer          not null
#  in_progress     :boolean          default(FALSE), not null
#  error_count     :jsonb
#  warning_count   :jsonb
#  entity_count    :jsonb
#
# Indexes
#
#  index_feed_version_gtfs_imports_on_feed_version_id  (feed_version_id) UNIQUE
#  index_feed_version_gtfs_imports_on_success          (success)
#

class GTFSImport < ActiveRecord::Base
    self.table_name = "feed_version_gtfs_imports"
    belongs_to :feed_version
    has_one :feed, through: :feed_version, source_type: 'Feed'  
    validates :feed_version, presence: true
end
  
