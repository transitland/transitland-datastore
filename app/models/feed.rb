# == Schema Information
#
# Table name: feeds
#
#  id               :integer          not null, primary key
#  url              :string(255)
#  feed_format      :string(255)
#  last_fetched_at  :datetime
#  last_imported_at :datetime
#  created_at       :datetime
#  updated_at       :datetime
#  tags             :hstore
#

class Feed < ActiveRecord::Base
  has_many :feed_imports, dependent: :destroy # -> { order('created_at DESC') },
  has_many :feed_import_errors, dependent: :destroy, through: :feed_imports
  has_many :operators_in_feed, dependent: :destroy
  has_many :operators, through: :operators_in_feed

  extend Enumerize
  enumerize :feed_format, in: [:gtfs], default: :gtfs

  validates :url, presence: true
  validates :url, format: { with: URI.regexp }, if: Proc.new { |feed| feed.url.present? }

  def fetch
    Feed.transaction do
      begin
        feed_import = FeedImport.new(feed: self)
        feed_import.file = URI.parse(url)
        feed_import.save!
        feed_import.update(successful_fetch: true)
        self.update(last_fetched_at: feed_import.created_at)
        # TODO: check feed_import.file_fingerprint against previous FeedImport
      rescue => e
        if feed_import
          FeedImportError.create(
            feed_import: feed_import,
            error_type: :fetch,
            body: e.inspect
          )
          feed_import.update(successful_fetch: false)
        else
          logger.warn e
        end
      end
    end
  end
end
