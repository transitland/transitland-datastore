# == Schema Information
#
# Table name: feeds
#
#  id                              :integer          not null, primary key
#  onestop_id                      :string
#  url                             :string
#  feed_format                     :string
#  tags                            :hstore
#  last_sha1                       :string
#  last_fetched_at                 :datetime
#  last_imported_at                :datetime
#  created_at                      :datetime
#  updated_at                      :datetime
#  license_name                    :string
#  license_url                     :string
#  license_use_without_attribution :string
#  license_create_derived_product  :string
#  license_redistribute            :string
#  operators_in_feed               :hstore           is an Array
#
# Indexes
#
#  index_feeds_on_onestop_id  (onestop_id)
#  index_feeds_on_tags        (tags)
#

require 'open-uri'

class Feed < ActiveRecord::Base
  include HasAOnestopId
  include HasTags

  PER_PAGE = 50

  has_many :feed_imports, -> { order 'created_at DESC' }, dependent: :destroy

  validates :url, presence: true
  validates :url, format: { with: URI.regexp }, if: Proc.new { |feed| feed.url.present? }
  validates :license_url, format: { with: URI.regexp }, if: Proc.new { |feed| feed.license_url.present? }

  extend Enumerize
  enumerize :feed_format, in: [:gtfs]
  enumerize :license_use_without_attribution, in: [:yes, :no, :unknown]
  enumerize :license_create_derived_product, in: [:yes, :no, :unknown]
  enumerize :license_redistribute, in: [:yes, :no, :unknown]

  after_initialize :set_default_values

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
      feed.operators_in_feed = feed_in_registry.operators_in_feed.map do |operator_in_feed|
        {
          gtfs_agency_id: operator_in_feed.gtfs_agency_id,
          onestop_id: operator_in_feed.operator_onestop_id,
          # identifiers: operator_in_feed.identifiers
        }
      end
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

  private

  def set_default_values
    if self.new_record?
      self.feed_format ||= 'gtfs'
      self.license_use_without_attribution ||= 'unknown'
      self.license_create_derived_product ||= 'unknown'
      self.license_redistribute ||= 'unknown'
    end
  end
end
