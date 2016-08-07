class Api::V1::IssuesController < Api::V1::BaseApiController
  include JsonCollectionPagination

  before_filter :require_api_auth_token, only: [:update, :create, :destroy]
  before_action :set_issue, only: [:show, :update, :destroy]

  def index
    @issues = Issue.where('')

    if params[:open].present?
      @issues = @issues.where(open: params[:open] == 'true')
    end

    if params[:issue_type].present?
      @issues = @issues.with_type(params[:issue_type])
    end

    if params[:feed_onestop_id].present?
      @issues = @issues.where(created_by_changeset: {imported_from_feed: { onestop_id: params[:feed_onestop_id] }})
    end

    # TODO: known n+1 query 
    @issues = @issues.includes([:entities_with_issues, created_by_changeset: [:imported_from_feed, :imported_from_feed_version]])

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @issues,
          Proc.new { |params| api_v1_issues_url(params) },
          params[:sort_key],
          params[:sort_order],
          params[:offset],
          params[:per_page],
          params[:total],
          params.slice(
            :open,
            :issue_type
          )
        )
      end
    end
  end

  def show
    render json: @issue
  end

  def update
    # TODO: allow for deletion of individual EntityWithIssues
    issue_params_copy = issue_params
    entities_with_issues_params = issue_params_copy.delete(:entities_with_issues).try(:compact)
    @issue.update!(issue_params_copy)
    entities_with_issues_params.each do |ewi|
      ewi_params[:entity] = OnestopId.find!(ewi_params.delete(:onestop_id))
      @issue.entities_with_issues << EntityWithIssues.find_or_initialize_by(ewi_params)
    end
    render json: @issue
  end

  def destroy
    @issue.destroy!
    render json: {}, status: :no_content
  end

  def create
    issue_params_copy = issue_params
    entities_with_issues_params = issue_params_copy.delete(:entities_with_issues).try(:compact)
    @issue = Issue.new(issue_params_copy)
    entities_with_issues_params.each { |ewi|
      ewi[:entity] = OnestopId.find!(ewi.delete(:onestop_id))
      @issue.entities_with_issues << EntityWithIssues.create(ewi)
    }
    @issue.created_by_changeset_id = issue_params_copy[:created_by_changeset_id] || @issue.changeset_from_entities.id

    existing_issue = Issue.find_by_equivalent(@issue)
    if existing_issue
      render json: existing_issue, status: :conflict
    else
      @issue.save!
      render json: @issue, status: :accepted
    end
  end

  private

  def set_entity_with_issues_params(ewi_params)
    ewi_params[:entity] = OnestopId.find!(ewi_params.delete(:onestop_id))
    @issue.entities_with_issues << EntityWithIssues.find_or_initialize_by(ewi_params)
  end

  def set_issue
    @issue = Issue.find(params[:id])
  end

  def issue_params
    params.require(:issue).permit(:id,
                                  :created_by_changeset_id,
                                  :resolved_by_changeset_id,
                                  :issue_type,
                                  :details,
                                  :open,
                                  entities_with_issues: [:onestop_id, :entity_attribute])
  end
end
