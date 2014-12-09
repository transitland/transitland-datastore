# == Schema Information
#
# Table name: feed_imports
#
#  id                :integer          not null, primary key
#  feed_id           :integer
#  successful_fetch  :boolean
#  successful_import :boolean
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  file_fingerprint  :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#
# Indexes
#
#  index_feed_imports_on_feed_id  (feed_id)
#

class FeedImport < ActiveRecord::Base
  belongs_to :feed
  has_many :feed_import_errors, dependent: :destroy

  has_attached_file :file
  validates_attachment_content_type :file, content_type: 'application/zip'
end
