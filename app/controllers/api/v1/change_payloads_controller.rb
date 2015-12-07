class Api::V1::ChangePayloadsController < Api::V1::BaseApiController
  include JsonCollectionPagination

  before_filter :require_api_auth_token, only: [:update]
  before_action :set_changeset, only: [:index]
  before_action :set_change_payload, only: [:show, :update]

  def index
    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @changeset.change_payloads,
          Proc.new { |params| api_v1_stops_url(params) },
          params[:offset],
          params[:per_page],
          params[:total],
          params.slice()
        )
      end
    end
  end

  def show
    render json: @change_payload
  end

  def update
    raise Changeset::Error.new(@changeset, 'cannot update a Changeset that has already been applied') if @changeset.applied
    @change_payload.update!(change_payload_params)
    render json: @change_payload
  end

  private

  def change_payload_params
    params.require(:changeset).slice(:payload)
  end

  def set_changeset
    @changeset = Changeset.find(params[:changeset_id])
  end

  def set_change_payload
    @changeset = Changeset.find(params[:changeset_id])
    @change_payload = ChangePayload.find(params[:id])
  end
end
