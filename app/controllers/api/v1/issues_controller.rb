class Api::V1::IssuesController < Api::V1::BaseApiController
  include JsonCollectionPagination

  before_action :set_issue, only: [:show, :update, :destroy]

  def index
    @issues = Issue.where('').includes{[entities_with_issues]}

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
    issue =  issue_params['created_by_changeset_id'] ? Issue.create!(filter_params(issue_params)) : nil
    issue_params['entities_with_issues'].each do |ewi|
      entity = OnestopId.find!(ewi['onestop_id'])
      issue = Issue.create!(filter_params(issue_params).update(created_by_changeset_id: entity.created_or_updated_in_changeset_id)) if issue.nil?
      issue.entities_with_issues.new(entity: entity, issue: issue, entity_attribute: ewi['entity_attribute'])
    end
    render json: issue
  end

  private

  def set_issue
    @issue = Issue.find(params[:id])
  end

  def filter_params(issue_params)
    issue_params.keep_if { |k,v| [:details,
                                  :created_by_changeset_id,
                                  :open,
                                  :block_changeset_apply,
                                  :issue_type].include?(k) }
  end

  def issue_params
    params.require(:issue).permit!
  end
end
