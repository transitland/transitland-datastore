class Api::V1::FeedImportsController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include DownloadableCsv

  before_action :set_feed

  def index
    @feed_imports = @feed.feed_imports

    per_page = params[:per_page].blank? ? FeedImport::PER_PAGE : params[:per_page].to_i

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @feed_imports,
          Proc.new { |params| api_v1_feed_feed_imports_url(params) },
          params[:offset],
          per_page
        )
      end
      format.csv do
        return_downloadable_csv(@feed_imports, 'feeds')
      end
    end
  end

  private

  def set_feed
    @feed = Feed.find_by(onestop_id: params[:feed_id])
  end
end
