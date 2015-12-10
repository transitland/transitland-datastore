class Api::V1::ChangePayloadsController < Api::V1::BaseApiController
  include JsonCollectionPagination

  before_filter :require_api_auth_token, only: [:update, :create, :destroy]
  before_action :set_changeset, only: [:index, :create]
  before_action :set_change_payload, only: [:show, :update, :destroy]

  def index
    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @changeset.change_payloads,
          Proc.new { |params| api_v1_changeset_change_payloads_url(params) },
          params[:offset],
          params[:per_page],
          params[:total],
          params.slice()
        )
      end
    end
  end

  def create
    @change_payload = @changeset.change_payloads.create(change_payload_params)
    render json: @change_payload
  end

  def show
    render json: @change_payload
  end

  def update
    raise Changeset::Error.new(@changeset, 'cannot update a Changeset that has already been applied') if @changeset.applied
    @change_payload.update!(change_payload_params)
    render json: @change_payload
  end

  def destroy
    @change_payload.destroy!
    render json: @change_payload
  end

  private

  def change_payload_params
    params.require(:change_payload).permit!
  end

  def set_changeset
    @changeset = Changeset.find(params[:changeset_id])
  end

  def set_change_payload
    @changeset = Changeset.find(params[:changeset_id])
    @change_payload = @changeset.change_payloads.find(params[:id])
  end
end
