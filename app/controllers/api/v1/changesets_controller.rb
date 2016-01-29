class Api::V1::ChangesetsController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include DownloadableCsv

  before_filter :require_api_auth_token, only: [:update, :check, :apply, :revert, :destroy]
  before_action :set_changeset, only: [:show, :update, :check, :apply, :revert, :destroy]

  def index
    @changesets = Changeset.where('').include{change_payloads}

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @changesets,
          Proc.new { |params| api_v1_changesets_url(params) },
          params[:offset],
          params[:per_page],
          params[:total],
          {}
        )
      end
      format.csv do
        return_downloadable_csv(@changesets, 'changesets')
      end
    end
  end

  def create
    user_params = changeset_params.delete(:user)
    @changeset = Changeset.new(changeset_params)
    if user_params.present?
      @changeset.set_user_by_params(user_params)
    end
    @changeset.save!
    return render json: @changeset
  end

  def destroy
    @changeset.destroy!
    render json: {}, status: :no_content
  end

  def update
    if @changeset.applied
      raise Changeset::Error.new(@changeset, 'cannot update a Changeset that has already been applied')
    else
      user_params = changeset_params.delete(:user)
      @changeset.update!(changeset_params)
      if user_params.present?
        @changeset.set_user_by_params(user_params)
        @changeset.save!
      end
      render json: @changeset
    end
  end

  def show
    render json: @changeset
  end

  def check
    trial_succeeds = @changeset.trial_succeeds?
    render json: { trialSucceeds: trial_succeeds }
  end

  def apply
    applied = @changeset.apply!
    render json: { applied: applied }
  end

  def revert
    @changeset.revert!
    @changeset.reload
    render json: @changeset
  end

  private

  def set_changeset
    @changeset = Changeset.find(params[:id])
  end

  def changeset_params
    params.require(:changeset).permit! # TODO: permit specific params
  end

  def change_params
    params.require(:change).permit! # TODO: permit specific params
  end

end
