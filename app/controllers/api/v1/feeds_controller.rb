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
      feed, operators = fetch_info_gtfs(file.path)
    ensure
      file.close
      file.unlink
    end
    feed.url = url
    render json: {
      url: url,
      feed: FeedSerializer.new(feed).as_json,
      operators: operators.map { |o| OperatorSerializer.new(o).as_json }
    }
  end

  private

  def set_feed
    @feed = Feed.find_by(onestop_id: params[:id])
  end

  def fetch_info_gtfs(filename)
    gtfs = GTFS::Source.build(filename, {strict: false})
    gtfs.load_graph
    stop_map = {}
    gtfs.stops.each do |stop|
      stop_map[stop] = Stop.from_gtfs(stop)
    end
    feed = Feed.from_gtfs(nil, stop_map.values)
    operators = []
    gtfs.agencies.each do |agency|
      agency_stops = Set.new
      gtfs.children(agency).each do |route|
        gtfs.children(route).each do |trip|
          gtfs.children(trip).each do |stop|
            agency_stops << stop_map[stop]
          end
        end
      end
      operator = Operator.from_gtfs(agency, agency_stops)
      operators << operator
      feed.operators_in_feed.new(gtfs_agency_id: agency.id, operator: operator, id: nil)
    end
    return [feed, operators]
  end
end
