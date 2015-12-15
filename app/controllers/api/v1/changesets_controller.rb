class Api::V1::ChangesetsController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include DownloadableCsv

  before_filter :require_api_auth_token, only: [:create, :destroy, :update, :check, :apply, :revert, :append]
  before_action :set_changeset, only: [:show, :destroy, :update, :check, :apply, :revert, :append]

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
    params_for_this_changeset = changeset_params
    when_to_apply = params_for_this_changeset.delete('whenToApply')
    @changeset = Changeset.new(changeset_params)
    if when_to_apply.presence == 'instantlyIfClean' && require_api_auth_token
      @changeset.save!
      trial_succeeds = @changeset.trial_succeeds?
      if trial_succeeds
        applied = @changeset.apply!
        return render json: { applied: applied }
      else
        return render json: { trialSucceeds: trial_succeeds }
      end
    else
      @changeset.save!
      return render json: @changeset
    end
  end

  def destroy
    @changeset.destroy!
    return render json: @changeset
  end

  def update
    if @changeset.applied
      raise Changeset::Error.new(@changeset, 'cannot update a Changeset that has already been applied')
    else
      @changeset.update!(changeset_params)
      render json: @changeset
    end
  end

  def append
    if @changeset.applied
      raise Changeset::Error.new(@changeset, 'cannot update a Changeset that has already been applied')
    else
      @changeset.append(params)
      @changeset.save!
      render json: { appended: true }
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
