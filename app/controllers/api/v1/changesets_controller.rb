class Api::V1::ChangesetsController < Api::V1::BaseApiController
  before_action :set_changeset, only: [:show, :check, :apply, :revert]

  def index
    @changesets = Changeset.where('')
    render json: @changesets
  end

  def create
    @changeset = Changeset.new(changeset_params)
    @changeset.save!
    render json: @changeset
  end

  def show
    render json: @changeset
  end

  def check
    is_valid_and_can_be_cleanly_applied = @changeset.is_valid_and_can_be_cleanly_applied?
    render json: { isValidAndCanBeCleanlyApplied: is_valid_and_can_be_cleanly_applied}
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
