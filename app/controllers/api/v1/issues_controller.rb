class Api::V1::IssuesController < Api::V1::BaseApiController
  include JsonCollectionPagination

  before_action :set_issue, only: [:show, :update, :destroy]

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

  def show
    puts @issue.to_json
    render json: @issue
  end

  def update
    @issue.update!(issue_params)
    render json: @issue
  end

  def destroy
    @issue.destroy!
    render json: {}, status: :no_content
  end

  def create
    #TODO check issue_type against available types
    entity = OnestopId.find!(issue_params['onestop_id'])
    issue = Issue.create!(issue_params.slice(:details).update(created_by_changeset_id: entity.created_or_updated_in_changeset_id))
    issue.entities_with_issues.new(entity: entity, issue: issue, entity_attribute: issue_params['entity_attribute'])
    render json: issue
  end

  private

  def set_issue
    @issue = Issue.find(params[:id])
  end

  def issue_params
    #TODO more required params
    params.require(:issue).permit(:details,
                                  :issue_type,
                                  :onestop_id,
                                  :created_by_changeset_id,
                                  :resolved_by_changeset_id,
                                  :entity_attribute,
                                  :open,
                                  :block_changeset_apply)
  end
end
