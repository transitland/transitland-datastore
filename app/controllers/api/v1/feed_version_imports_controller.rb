class Api::V1::FeedVersionImportsController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include AllowFiltering
  include DownloadableCsv

  before_action :set_feed_version_import, only: [:show]

  # GET /feed_version_imports
  include Swagger::Blocks
  swagger_path '/feed_version_imports' do
    operation :get do
      key :tags, ['feed']
      key :name, :tags
      key :summary, 'Returns all feed version imports with filtering and sorting'
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
      parameter do
        key :name, :servedBy
        key :in, :query
        key :description, 'operator Onestop ID(s) to filter by'
        key :required, false
        key :type, :string
      end
      response 200 do
        # key :description, 'stop response'
        schema do
          key :type, :array
          items do
            key :'$ref', :FeedVersionImport
          end
        end
      end
    end
  end
  def index
    @feed_version_imports = FeedVersionImport.where('')

    @feed_version_imports = AllowFiltering.by_primary_key_ids(@feed_version_imports, params)

    if params[:feed_onestop_id].present?
      feed_onestop_ids = params[:feed_onestop_id].split(',')
      @feed_versions = @feed_version_imports.where(feed: Feed.where(onestop_id: feed_onestop_ids))
    end

    if params[:feed_version_sha1].present?
      feed_version_sha1s = params[:feed_version_sha1].split(',')
      @feed_versions = @feed_versions.where(feed_version: FeedVersion.where(sha1: feed_version_sha1s))
    end

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @feed_version_imports,
          Proc.new { |params| api_v1_feed_version_imports_url(params) },
          params[:sort_key],
          params[:sort_order],
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

  # GET /feed_version_imports/{id}
  include Swagger::Blocks
  swagger_path '/feed_version_imports/{id}' do
    operation :get do
      key :tags, ['feed']
      key :name, :tags
      key :summary, 'Returns a single feed version import'
      key :produces, ['application/json']
      parameter do
        key :name, :id
        key :in, :path
        key :description, 'ID for feed version import'
        key :required, true
        key :type, :integer
      end
      response 200 do
        # key :description, 'stop response'
        schema do
          key :'$ref', :FeedVersionImport
        end
      end
    end
  end
  def show
    render json: @feed_version_import
  end

  private

  def set_feed_version_import
    @feed_version_import = FeedVersionImport.find(params[:id])
  end
end
