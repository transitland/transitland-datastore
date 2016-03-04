class Api::V1::FeedsController < Api::V1::BaseApiController
  include Geojson
  include JsonCollectionPagination
  include DownloadableCsv
  include AllowFiltering

  before_action :set_feed, only: [:show]

  # GET /feeds
  include Swagger::Blocks
  swagger_path '/feeds' do
    operation :get do
      key :tags, ['feed']
      key :name, :tags
      key :summary, 'Returns all feeds with filtering and sorting'
      key :produces, [
        'application/json',
        'application/vnd.geo+json',
        'text/csv'
      ]
      parameter do
        key :name, :onestop_id
        key :in, :query
        key :description, 'Onestop ID(s) to filter by'
        key :required, false
        key :type, :string
      end
      response 200 do
        # key :description, 'stop response'
        schema do
          key :type, :array
          items do
            key :'$ref', :Feed
          end
        end
      end
    end
  end
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

    if params[:bbox].present?
      @feeds = @feeds.geometry_within_bbox(params[:bbox])
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

  # GET /feeds/{onestop_id}
  include Swagger::Blocks
  swagger_path '/feeds/{onestop_id}' do
    operation :get do
      key :tags, ['feed']
      key :name, :tags
      key :summary, 'Returns a single feed'
      key :produces, [
        'application/json',
        # TODO: 'application/vnd.geo+json'
      ]
      parameter do
        key :name, :onestop_id
        key :in, :path
        key :description, 'Onestop ID for feed'
        key :required, true
        key :type, :string
      end
      response 200 do
        # key :description, 'stop response'
        schema do
          key :'$ref', :FeedVersion
        end
      end
    end
  end
  def show
    render json: @feed
  end

  # POST /feeds/fetch_info
  include Swagger::Blocks
  swagger_path '/feeds/fetch_info' do
    operation :post do
      key :tags, ['feed']
      key :name, :tags
      key :summary, 'Fetch feed from URL and parse its contents'
      key :description, 'Used by Transitland Feed Registry to parse a feed, in prepartion for adding the feed to the Datastore.'
      key :produces, ['application/json']
      parameter do
        key :name, :url
        key :in, :body
        key :description, 'URL from which to fetch GTFS feed'
        key :required, true
        key :type, :string
      end
      response 200 do
        # key :description, 'stop response'
        schema do
          # key :'$ref', :FeedVersion
        end
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
      cachedata = {status: 'processing', url: url}
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
    @feed = Feed.find_by(onestop_id: params[:id])
  end

end
