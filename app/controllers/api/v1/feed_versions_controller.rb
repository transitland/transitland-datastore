class Api::V1::FeedVersionsController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include DownloadableCsv
  include AllowFiltering

  before_action :set_feed_version, only: [:show]

  def index
    @feed_versions = FeedVersion.where('').includes{[
      feed,
      feed_version_imports,
      feed.active_feed_version,
      changesets_imported_from_this_feed_version
    ]}

    @feed_versions = AllowFiltering.by_updated_since(@feed_versions, params)

    if params[:ids].present? || params[:sha1].present?
      sha1s = []
      if params[:sha1].present?
        if params[:sha1].is_a?(Array) # for Ember Data
          sha1s += params[:sha1]
        elsif params[:sha1].is_a?(String)
          sha1s += params[:sha1].split(',')
        end
      end
      if params[:ids].present?
        if params[:ids].is_a?(Array) # for Ember Data
          sha1s += params[:ids]
        elsif params[:ids].is_a?(String)
          sha1s += params[:ids].split(',')
        end
      end
      @feed_versions = @feed_versions.where(sha1: sha1s)
    end

    if params[:feed_onestop_id].present?
      feed_onestop_ids = params[:feed_onestop_id].split(',')
      @feed_versions = @feed_versions.where(feed: Feed.where(onestop_id: feed_onestop_ids))
    end

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @feed_versions,
          Proc.new { |params| api_v1_feed_versions_url(params) },
          params[:offset],
          params[:per_page],
          params[:total],
          {}
        )
      end
      format.csv do
        return_downloadable_csv(@feed_versions, 'feed_versions')
      end
    end
  end

  def show
    render json: @feed_version
  end

  private

  def set_feed_version
    @feed_version = FeedVersion.find_by!(sha1: params[:id])
  end
end
