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
    file = Tempfile.new('test.zip', Dir.tmpdir, 'wb+')
    file.binmode
    begin
      response = Faraday.get(url)
      file.write(response.body)
      file.close
      operators = gtfs_create_operators(file.path)
    ensure
      file.close
      file.unlink
    end
    feed = nil
    render json: {
      url: url,
      feed: feed,
      operators: operators
    }
  end

  private

  def set_feed
    @feed = Feed.find_by(onestop_id: params[:id])
  end

  def gtfs_create_operators(filename)
    gtfs = GTFS::Source.build(filename, {strict: false})
    gtfs.load_graph
    operators = {}
    gtfs.agencies.each do |agency|
      stops = Set.new
      gtfs.children(agency).each do |route|
        gtfs.children(route).each do |trip|
          gtfs.children(trip).each do |stop|
            stops.add(stop)
          end
        end
      end
      stops = stops.map { |stop| Stop.from_gtfs(stop) }
      operator = Operator.from_gtfs(agency, stops)
      operators[operator.onestop_id] = operator
      # TODO: Pass through Operator serializer
    end
    operators.values
  end
end
