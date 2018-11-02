class Api::V1::FeedVersionImportsController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include AllowFiltering
  include DownloadableCsv

  before_action :set_feed_version_import, only: [:show]

  def index
    @feed_version_imports = FeedVersionImport.where('')
    @feed_version_imports = AllowFiltering.by_primary_key_ids(@feed_version_imports, params)

    if params[:feed_onestop_id].present?
      feed_onestop_ids = params[:feed_onestop_id].split(',')
      @feed_versions = @feed_version_imports.where(feed: Feed.where(onestop_id: feed_onestop_ids))
    end

    if params[:feed_version_sha1].present?
      feed_version_sha1s = params[:feed_version_sha1].split(',')
      @feed_versions = @feed_version_imports.where(feed_version: FeedVersion.where(sha1: feed_version_sha1s))
    end

    respond_to do |format|
      format.json { render paginated_json_collection(@feed_version_imports) }
      format.csv { return_downloadable_csv(@feed_version_imports, 'feed_version_imports') }
    end
  end

  def show
    render json: @feed_version_import
  end

  private

  def query_params
    super.merge({
      ids: {
        desc: "FeedVersionImport IDs",
        type: "integer",
        array: true
      },
      feed_onestop_id: {
        desc: "Feed",
        type: "onestop_id",
        array: true
      },
      feed_version_sha1: {
        desc: "Feed Version",
        type: "sha1",
        array: true
      }
    })
  end

  def set_feed_version_import
    @feed_version_import = FeedVersionImport.find(params[:id])
  end
end
