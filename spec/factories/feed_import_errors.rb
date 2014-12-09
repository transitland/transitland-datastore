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

FactoryGirl.define do
  factory :feed_import_error do
    feed_import
    error_type { FeedImportError.error_type.values.sample }
  end

end
