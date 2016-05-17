class Api::V1::IssuesController < Api::V1::BaseApiController
  include JsonCollectionPagination
  def index
    @issues = Issue.where('')

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @issues,
          Proc.new { |params| api_v1_routes_url(params) },
          params[:sort_key],
          params[:sort_order],
          params[:offset],
          params[:per_page],
          params[:total],
          params
        )
      end
    end
  end
end
