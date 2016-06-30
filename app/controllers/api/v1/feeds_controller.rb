class Api::V1::FeedsController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include DownloadableCsv
  include AllowFiltering
  include Geojson
  GEOJSON_ENTITY_PROPERTIES = Proc.new { |properties, entity|
    # title property to follow GeoJSON simple style spec
    properties[:title] = "Feed #{entity.onestop_id}"

    properties[:url] = entity.url
    properties[:feed_format] = entity.feed_format
    properties[:license_name] = entity.license_name
    properties[:license_url] = entity.license_url
    properties[:license_use_without_attribution] = entity.license_use_without_attribution
    properties[:license_create_derived_product] = entity.license_create_derived_product
    properties[:license_redistribute] = entity.license_redistribute
    properties[:license_attribution_text] = entity.license_attribution_text
    properties[:last_fetched_at] = entity.last_fetched_at
    properties[:latest_fetch_exception_log] = entity.latest_fetch_exception_log
    properties[:import_status] = entity.import_status
    properties[:last_imported_at] = entity.last_imported_at
    properties[:feed_versions_count] = entity.feed_versions.count
    properties[:active_feed_version] = entity.active_feed_version
    properties[:import_level_of_active_feed_version] = entity.active_feed_version.try(:import_level)
    properties[:created_or_updated_in_changeset_id] = entity.created_or_updated_in_changeset_id
  }

  before_action :set_feed, only: [:show]

  def index
    @feeds = Feed.where('').includes{[
      operators_in_feed,
      operators_in_feed.operator,
      changesets_imported_from_this_feed,
      active_feed_version,
      feed_versions
    ]}

    @feeds = AllowFiltering.by_onestop_id(@feeds, params)
    @feeds = AllowFiltering.by_tag_keys_and_values(@feeds, params)
    @feeds = AllowFiltering.by_attribute_since(@feeds, params, :last_imported_since, :last_imported_at)

    if params[:latest_fetch_exception].present?
      @feeds = @feeds.where_latest_fetch_exception(AllowFiltering.to_boolean(params[:latest_fetch_exception]))
    end

    if params[:bbox].present?
      @feeds = @feeds.geometry_within_bbox(params[:bbox])
    end

    if params[:active_feed_version_valid].present?
      @feeds = @feeds.where_active_feed_version_valid(params[:active_feed_version_valid])
    end

    if params[:active_feed_version_expired].present?
      @feeds = @feeds.where_active_feed_version_expired(params[:active_feed_version_expired])
    end

    if params[:active_feed_version_update].presence == 'true'
      @feeds = @feeds.where_active_feed_version_update
    end

    if params[:active_feed_version_import_level].present?
      @feeds = @feeds.where_active_feed_version_import_level(params[:active_feed_version_import_level])
    end

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @feeds,
          Proc.new { |params| api_v1_feeds_url(params) },
          params[:sort_key],
          params[:sort_order],
          params[:offset],
          params[:per_page],
          params[:total],
          params.slice(
            :tag_key,
            :tag_value,
            :last_imported_since,
            :active_feed_version_valid,
            :active_feed_version_expired,
            :active_feed_version_update
          )
        )
      end
      format.geojson do
        render json: Geojson.from_entity_collection(@feeds, &GEOJSON_ENTITY_PROPERTIES)
      end
      format.csv do
        return_downloadable_csv(@feeds, 'feeds')
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @feed
      end
      format.geojson do
        render json: Geojson.from_entity(@feed, &GEOJSON_ENTITY_PROPERTIES)
      end
    end
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

  private

  def set_feed
    @feed = Feed.find_by_onestop_id!(params[:id])
  end

end
