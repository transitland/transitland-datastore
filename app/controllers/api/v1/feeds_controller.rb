class Api::V1::FeedsController < Api::V1::BaseApiController
  include Geojson
  include JsonCollectionPagination
  include DownloadableCsv

  before_action :set_feed, only: [:show]

  def index
    @feeds = Feed.where('').includes{[operators_in_feed, operators_in_feed.operator]}

    if params[:tag_key].present? && params[:tag_value].present?
      @feeds = @feeds.with_tag_equals(params[:tag_key], params[:tag_value])
    elsif params[:tag_key].present?
      @feeds = @feeds.with_tag(params[:tag_key])
    elsif params[:bbox].present?
      @feeds = @feeds.geometry_within_bbox(params[:bbox])
    end

    @feeds = @feeds.includes{[operators_in_feed]}

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @feeds,
          Proc.new { |params| api_v1_feeds_url(params) },
          params[:offset],
          params[:per_page],
          params[:total],
          params.slice(:tag_key, :tag_value)
        )
      end
      format.geojson do
        render json: Geojson.from_entity_collection(@feeds)
      end
      format.csv do
        return_downloadable_csv(@feeds, 'feeds')
      end
    end
  end

  def show
    render json: @feed
  end

  def fetch_info
    url = params[:url]
    raise Exception.new('invalid URL') unless url
    # Use read/write instead of fetch block to avoid race with Sidekiq.
    cachekey = "feeds/fetch_info/#{url}"
    cachedata = Rails.cache.read(cachekey)
    if !cachedata
      cachedata = {status: 'processing', url: url}
      Rails.cache.write(cachekey, cachedata, expires_in: 1.hour)
      FeedInfoWorker.perform_async(url, cachekey)
    end
    render json: cachedata
  end

  private

  def set_feed
    @feed = Feed.find_by(onestop_id: params[:id])
  end

end
