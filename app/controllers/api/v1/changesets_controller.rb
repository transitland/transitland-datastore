class Api::V1::ChangesetsController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include DownloadableCsv
  include AllowFiltering

  before_filter :require_api_auth_token, only: [:update, :check, :apply, :revert, :destroy]
  before_action :set_changeset, only: [:show, :update, :check, :apply, :revert, :destroy]

  def index
    @changesets = Changeset.where('').include{[
      imported_from_feed,
      imported_from_feed_version,
      feeds_created_or_updated,
      feeds_destroyed,
      stops_created_or_updated,
      stops_destroyed,
      operators_created_or_updated,
      operators_destroyed,
      routes_created_or_updated,
      routes_destroyed,
      user
    ]}
    # ^^^ that's a lot of queries. TODO: check performance.

    @changesets = AllowFiltering.by_primary_key_ids(@changesets, params)
    @changesets = AllowFiltering.by_boolean_attribute(@changesets, params, :applied)

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @changesets,
          Proc.new { |params| api_v1_changesets_url(params) },
          params[:sort_key],
          params[:sort_order],
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
    user_params = changeset_params.delete(:user).try(:compact)
    change_payload_params = changeset_params.delete(:change_payloads).try(:compact)
    @changeset = Changeset.new(changeset_params)
    if user_params.present?
      user_params.delete(:id) # because that could be sent by Ember, and we'd rather match on email
      @changeset.set_user_by_params(user_params)
    end
    if change_payload_params.present?
      change_payload_params.each do |change_payload_param|
        @changeset.change_payloads.new(change_payload_param)
      end
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
      raise Changeset::Error.new(changeset: @changeset, message: 'cannot update a Changeset that has already been applied')
    else
      user_params = changeset_params.delete(:user).try(:compact)

      # NOTE: can't currently use this endpoint to edit existing payloads.
      # Use PUT /api/v1/changeset/x/change_payloads instead.
      changeset_params.delete(:change_payloads)

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
    trial_succeeds, issues = @changeset.trial_succeeds?
    render json: {trialSucceeds: trial_succeeds, issues: issues.as_json }
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
    params.require(:changeset).permit!
    # We'll rely on changeset JSON schemas to validate the incoming contents.
  end

end
