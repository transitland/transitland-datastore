class Api::V1::ChangePayloadsController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include AllowFiltering

  before_filter :require_api_auth_token, only: [:update, :create, :destroy]
  before_action :set_changeset, only: [:index, :create]
  before_action :set_change_payload, only: [:show, :update, :destroy]
  before_action :changeset_applied_lock, only: [:create, :update, :destroy]

  def index
    @change_payloads = @changeset.change_payloads

    @change_payloads = AllowFiltering.by_primary_key_ids(@change_payloads, params)

    respond_to do |format|
      format.json do
        render paginated_json_collection(@change_payloads)
      end
    end
  end

  def create
    @change_payload = @changeset.change_payloads.create!(change_payload_params)
    render json: @change_payload
  end

  def show
    render json: @change_payload
  end

  def update
    @change_payload.update!(change_payload_params)
    render json: @change_payload
  end

  def destroy
    @change_payload.destroy!
    render json: {}, status: :no_content
  end

  private

  def change_payload_params
    params.require(:change_payload).permit!
  end

  def changeset_applied_lock
    raise Changeset::Error.new(changeset: @changeset, message: 'cannot update a Changeset that has already been applied') if @changeset.applied
  end

  def set_changeset
    @changeset = Changeset.find(params[:changeset_id])
  end

  def set_change_payload
    @changeset = Changeset.find(params[:changeset_id])
    @change_payload = @changeset.change_payloads.find(params[:id])
  end
end
