class Api::V1::OnestopIdController < Api::V1::BaseApiController
  def show
    entity = OnestopId.find!(params[:onestop_id])
    render json: entity
  end

  def query_params
    super.merge({
      onestop_id: {
        desc: "Onestop ID",
        type: "onestop_id"
      }
    })
  end
end
