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
    render json: @issue
  end

  def update
    entities_with_issues_params = issue_params.delete(:entities_with_issues).try(:compact)
    @issue.update!(issue_params)
    entities_with_issues_params.each do |ewi|
      @issue.set_entity_with_issues_params(ewi)
    end
    render json: @issue
  end

  def destroy
    @issue.destroy!
    render json: {}, status: :no_content
  end

  def create
    entities_with_issues_params = issue_params.delete(:entities_with_issues).try(:compact)
    issue =  issue_params.has_key?(:created_by_changeset_id) ? Issue.create!(filter_params(issue_params)) : nil
    entities_with_issues_params.each do |ewi|
      entity = OnestopId.find!(ewi['onestop_id'])
      issue = Issue.create!(issue_params.update(created_by_changeset_id: entity.created_or_updated_in_changeset_id)) if issue.nil?
      issue.set_entity_with_issues_params(ewi)
    end
    render json: issue
  end

  private

  def set_issue
    @issue = Issue.find(params[:id])
  end

  def issue_params
    params.require(:issue).permit!
  end
end
