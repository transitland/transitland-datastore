class Api::V1::OnestopIdController < Api::V1::BaseApiController
  def show
    entity = OnestopId.find!(params[:onestop_id])
    render json: entity
  end
end
