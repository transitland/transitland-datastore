# == Schema Information
#
# Table name: feed_import_errors
#
#  id             :integer          not null, primary key
#  feed_import_id :integer
#  error_type     :string(255)
#  body           :text
#  created_at     :datetime
#  updated_at     :datetime
#
# Indexes
#
#  index_feed_import_errors_on_feed_import_id  (feed_import_id)
#

describe FeedImportError do
  pending "add some examples to (or delete) #{__FILE__}"
end
