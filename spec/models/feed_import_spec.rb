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

describe FeedImport do
  pending "add some examples to (or delete) #{__FILE__}"
end
