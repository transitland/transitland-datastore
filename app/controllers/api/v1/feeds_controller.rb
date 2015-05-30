class Api::V1::FeedsController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include DownloadableCsv

  before_action :set_feed, only: [:show]

  def index
    @feeds = Feed.where('')

    if params[:tag_key].present? && params[:tag_value].present?
      @feeds = @feeds.with_tag(params[:tag_key], params[:tag_value])
    end

    per_page = params[:per_page].blank? ? Feed::PER_PAGE : params[:per_page].to_i

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @feeds,
          Proc.new { |params| api_v1_feeds_url(params) },
          params[:offset],
          per_page
        )
      end
      format.csv do
        return_downloadable_csv(@feeds, 'feeds')
      end
    end
  end

  def show
    render json: @feed
  end

  private

  def set_feed
    @feed = Feed.find_by(onestop_id: params[:id])
  end
end
