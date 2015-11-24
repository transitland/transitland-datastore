class Api::V1::FeedVersionImportsController < Api::V1::BaseApiController
  include JsonCollectionPagination
  PER_PAGE = 1

  include DownloadableCsv

  before_action :set_feed
  before_action :set_feed_version
  before_action :set_feed_version_import, only: [:show]

  def index
    @feed_version_imports = @feed_version.feed_version_imports

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @feed_version_imports,
          Proc.new { |params| api_v1_feed_feed_version_feed_version_imports_url(params) },
          params[:offset],
          params[:per_page],
          params[:total],
          {}
        )
      end
      format.csv do
        return_downloadable_csv(@feed_version_imports, 'feed_version_imports')
      end
    end
  end

  def show
    render json: @feed_version_import
  end

  private

  def set_feed
    @feed = Feed.find_by!(onestop_id: params[:feed_id])
  end

  def set_feed_version
    @feed_version = @feed.feed_versions.find_by!(sha1: params[:feed_version_id])
  end

  def set_feed_version_import
    @feed_version_import = @feed_version.feed_version_imports.find(params[:id])
  end
end
