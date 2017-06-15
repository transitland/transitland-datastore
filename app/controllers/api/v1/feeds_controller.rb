class Api::V1::FeedsController < Api::V1::EntityController
  before_action :set_model, only: [:download_latest_feed_version]

  def self.model
    Feed
  end

  def fetch_info
    url = params[:url]
    raise Exception.new('invalid URL') if url.empty?
    # Use read/write instead of fetch block to avoid race with Sidekiq.
    cachekey = "feeds/fetch_info/#{url}"
    cachedata = Rails.cache.read(cachekey)
    if !cachedata
      cachedata = {status: 'queued', url: url}
      Rails.cache.write(cachekey, cachedata, expires_in: FeedInfo::CACHE_EXPIRATION)
      FeedInfoWorker.perform_async(url, cachekey)
    end
    if cachedata[:status] == 'error'
      render json: cachedata, status: 500
    else
      render json: cachedata
    end
  end

  def download_latest_feed_version
    feed_version = @model.feed_versions.order(fetched_at: :desc).first!
    if feed_version.download_url.present?
      redirect_to feed_version.download_url, status: 302
    else
      fail ActiveRecord::RecordNotFound, "Either no feed versions are available for this feed or their license prevents redistribution"
    end
  end

  private

  def index_query
    super
    @collection = AllowFiltering.by_attribute_array(@collection, params, :url, case_sensitive: true)
    @collection = AllowFiltering.by_attribute_since(@collection, params, :last_imported_since, :last_imported_at)
    if params[:latest_fetch_exception].present?
      @collection = @collection.where_latest_fetch_exception(AllowFiltering.to_boolean(params[:latest_fetch_exception]))
    end
    if params[:active_feed_version_valid].present?
      @collection = @collection.where_active_feed_version_valid(params[:active_feed_version_valid])
    end
    if params[:active_feed_version_expired].present?
      @collection = @collection.where_active_feed_version_expired(params[:active_feed_version_expired])
    end
    if params[:active_feed_version_update].presence == 'true'
      @collection = @collection.where_active_feed_version_update
    end
    if params[:active_feed_version_import_level].present?
      @collection = @collection.where_active_feed_version_import_level(params[:active_feed_version_import_level])
    end
    if params[:latest_feed_version_import_status].present?
      @collection = @collection.where_latest_feed_version_import_status(AllowFiltering.to_boolean(params[:latest_feed_version_import_status]))
    end
  end

  def index_includes
    super
    @collection = @collection.includes{[
      changesets_imported_from_this_feed,
      operators_in_feed,
      operators_in_feed.operator,
      active_feed_version
    ]}
  end

  def query_params
    super.merge({
      last_imported_since: {
        desc: "Last imported since",
        type: "datetime"
      },
      latest_fetch_exception: {
        desc: "Latest fetch produced an exception",
        type: "boolean"
      },
      active_feed_version_valid: {
        desc: "The active Feed Version is valid on this date",
        type: "datetime"
      },
      active_feed_version_expired: {
        desc: "The active Feed Version is expired on this date",
        type: "datetime"
      },
      active_feed_version_update: {
        desc: "There is a newer Feed Version than the current active Feed Version",
        type: "boolean"
      },
      active_feed_version_import_level: {
        desc: "Import level of the active Feed Version",
        type: "integer"
      },
      latest_feed_version_import_status: {
        desc: "Status of the most recent import",
        type: "string"
      },
      url: {
        desc: "URL",
        type: "string",
        array: true
      }
    })
  end

  def sort_reorder(collection)
    if sort_key == 'latest_feed_version_import.created_at'.to_sym
      collection = collection.with_latest_feed_version_import
      collection.reorder("latest_feed_version_import.created_at #{sort_order}")
    else
      super
    end
  end
end
