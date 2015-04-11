class Api::V1::ChangesetsController < Api::V1::BaseApiController
  before_filter :require_api_auth_token, only: [:create, :update, :check, :apply, :revert]
  before_action :set_changeset, only: [:show, :update, :check, :apply, :revert]

  def index
    @changesets = Changeset.where('')
    render json: @changesets
  end

  def create
    params_for_this_changeset = changeset_params
    when_to_apply = params_for_this_changeset.delete('whenToApply')
    @changeset = Changeset.new(changeset_params)
    if when_to_apply.present? && when_to_apply == 'instantlyIfClean'
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

  def update
    if @changeset.applied
      raise Changeset::Error.new(@changeset, 'cannot update a Changeset that has already been applied')
    else
      @changeset.update(changeset_params)
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
end
