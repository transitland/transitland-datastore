# == Schema Information
#
# Table name: feeds
#
#  id                           :integer          not null, primary key
#  onestop_id                   :string
#  url                          :string
#  feed_format                  :string
#  tags                         :hstore
#  operator_onestop_ids_in_feed :string           default([]), is an Array
#  last_sha1                    :string
#  last_fetched_at              :datetime
#  last_imported_at             :datetime
#  created_at                   :datetime
#  updated_at                   :datetime
#
# Indexes
#
#  index_feeds_on_onestop_id  (onestop_id)
#

require 'open-uri'

class Feed < ActiveRecord::Base
  include HasAOnestopId

  PER_PAGE = 50

  has_many :feed_imports, -> { order 'created_at DESC' }, dependent: :destroy

  validates :url, presence: true
  validates :url, format: { with: URI.regexp }, if: Proc.new { |feed| feed.url.present? }

  def fetch_and_check_for_updated_version
    begin
      logger.info "Fetching feed #{onestop_id} from #{url}"
      File.open(file_path, 'wb') do |file|
        open(url) do |resp|
          file.write(resp.read)
        end
      end

      if last_sha1 == file_sha1_hash
        logger.info "File downloaded from #{url} has same sha1 hash as last imported version"
        false
      else
        logger.info "File downloaded from #{url} has a new sha1 hash"
        true
      end
    rescue
      logger.error "Error fetching feed ##{onestop_id}"
      logger.error $!.message
      logger.error $!.backtrace
      false
    end
  end

  def file_path
    File.join(Figaro.env.transitland_feed_data_path, "#{onestop_id}.zip")
  end

  def file_sha1_hash
    Digest::SHA1.file(file_path).hexdigest
  end

  def has_been_fetched_and_imported!(on_feed_import: nil)
    sha1 = file_sha1_hash
    update(
      last_fetched_at: DateTime.now,
      last_imported_at: DateTime.now,
      last_sha1: sha1
    )
    on_feed_import.update(
      success: true,
      sha1: sha1
    ) if on_feed_import
  end

  def self.update_feeds_from_feed_registry
    logger.info 'Fetching current version of Feed Registry'
    TransitlandClient::FeedRegistry.repo(force_update: true)
    logger.info 'Updating feed records from Feed Registry'
    TransitlandClient::Entities::Feed.all.each do |feed_in_registry|
      feed = Feed.find_or_create_by(onestop_id: feed_in_registry.onestop_id)
      feed.url = feed_in_registry.url
      feed.operator_onestop_ids_in_feed = feed_in_registry.operators_in_feed.map(&:operator_onestop_id)
      feed.feed_format = feed_in_registry.feed_format
      feed.tags = feed_in_registry.tags
      feed.save!
    end
  end

  def self.fetch_and_check_for_updated_version(feed_onestop_ids = [])
    feeds_with_updated_versions = []
    feeds = feed_onestop_ids.length > 0 ? where(onestop_id: feed_onestop_ids) : where('')
    feeds.each do |feed|
      is_updated_version = feed.fetch_and_check_for_updated_version
      feeds_with_updated_versions << feed if is_updated_version
    end
    feeds_with_updated_versions
  end
end
