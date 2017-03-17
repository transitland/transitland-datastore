# == Schema Information
#
# Table name: feed_versions
#
#  id                     :integer          not null, primary key
#  feed_id                :integer
#  feed_type              :string
#  file                   :string
#  earliest_calendar_date :date
#  latest_calendar_date   :date
#  sha1                   :string
#  md5                    :string
#  tags                   :hstore
#  fetched_at             :datetime
#  imported_at            :datetime
#  created_at             :datetime
#  updated_at             :datetime
#  import_level           :integer          default(0)
#
# Indexes
#
#  index_feed_versions_on_feed_type_and_feed_id  (feed_type,feed_id)
#

class Api::V1::FeedVersionInfosController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include DownloadableCsv
  include AllowFiltering

  before_action :set_feed_version_info, only: [:show, :update]

  def index
    @feed_version_infos = FeedVersionInfo.where('').includes{[
      feed,
      feed_version
    ]}
    @feed_version_infos = AllowFiltering.by_primary_key_ids(@feed_version_infos, params)

    if params[:feed_onestop_id].present?
      feed_onestop_ids = params[:feed_onestop_id].split(',')
      # @feed_version_infos = @feed_version_infos.where(feed: Feed.where(onestop_id: feed_onestop_ids))
    end

    if params[:feed_version_sha1].present?
      feed_version_sha1s = params[:feed_version_sha1].split(',')
      # @feed_version_infos = @feed_version_infos.where(feed_version: FeedVersion.where(sha1: feed_version_sha1s))
    end

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

  private

  def set_feed_version_info
    # @feed_version_info = FeedVersion.find_by!(sha1: params[:id]).feed_version_info
    @feed_version_info = FeedVersionInfo.find(params[:id])
  end
end
