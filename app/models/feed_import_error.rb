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

class FeedImportError < ActiveRecord::Base
  belongs_to :feed_import

  extend Enumerize
  enumerize :error_type, in: [
    :misc,
    :fetch
  ]
end
