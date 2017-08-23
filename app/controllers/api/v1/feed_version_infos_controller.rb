# == Schema Information
#
# Table name: feed_version_infos
#

class Api::V1::FeedVersionInfosController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include DownloadableCsv
  include AllowFiltering

  before_action :set_feed_version_info, only: [:show, :update]

  def index
    @feed_version_infos = FeedVersionInfo.where('')
    @feed_version_infos = AllowFiltering.by_primary_key_ids(@feed_version_infos, params)

    if params[:feed_version_sha1].present?
      feed_versions = FeedVersion.where(sha1: AllowFiltering.param_as_array(params, :feed_version_sha1))
      @feed_version_infos = @feed_version_infos.where(feed_version: feed_versions)
    end

    if params[:feed_onestop_id].present?
      feeds = Feed.find_by_onestop_ids!(AllowFiltering.param_as_array(params, :feed_onestop_id))
      @feed_version_infos = @feed_version_infos.where_feed(feeds)
    end

    if params[:type].present?
      @feed_version_infos = @feed_version_infos.where_type(AllowFiltering.param_as_array(params, :type))
    end

    @feed_version_infos = @feed_version_infos.includes{[
      feed_version,
      # feed_version.feed # TODO: various polymorphic relations in feed_version prevent this
    ]}

    respond_to do |format|
      format.json { render paginated_json_collection(@feed_version_infos) }
      format.csv { return_downloadable_csv(@feed_version_infos, 'feed_version_infos') }
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @feed_version_info }
    end
  end

  def paginated_json_collection(collection)
    result = super
    result[:root] = :feed_version_infos
    result[:each_serializer] = FeedVersionInfoSerializer
    result
  end

  private

  def query_params
    super.merge({
      feed_onestop_id: {
        desc: "Feed",
        type: "onestop_id",
        array: true
      },
      feed_version_sha1: {
        desc: "Feed Version",
        type: "sha1",
        array: true
      },
      type: {
        desc: "Feed Version Info Type",
        type: "enum",
        enum: ["FeedVersionInfoStatistics","FeedVersionInfoConveyal"],
        array: true
      },
      id: {
        desc: "Feed Version Info ID",
        type: "integer",
        array: true
      }
    })
  end

  def set_feed_version_info
    # @feed_version_info = FeedVersion.find_by!(sha1: params[:id]).feed_version_info
    @feed_version_info = FeedVersionInfo.find(params[:id])
  end
end
