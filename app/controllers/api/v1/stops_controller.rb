class Api::V1::StopsController < Api::V1::BaseApiController
  before_action :set_stop, only: [:show, :update, :destroy]

  def index
    @stops = Stop.where('')
    if params[:identifier].present?
      @stops = @stops.joins(:stop_identifiers).where("stop_identifiers.identifier = ?", params[:identifier])
    end
    if [params[:lat], params[:lon]].map(&:present?).all?
      point = Stop::GEOFACTORY.point(params[:lon], params[:lat])
      r = params[:r] || 100 # meters TODO: move this to a more logical place
      @stops = @stops.where{st_dwithin(geometry, point, r)}.order{st_distance(geometry, point)}
    end
    if params[:bbox].present? && params[:bbox].split(',').length == 4
      bbox_coordinates = params[:bbox].split(',')
      @stops = @stops.where{geometry.op('&&', st_makeenvelope(bbox_coordinates[0], bbox_coordinates[1], bbox_coordinates[2], bbox_coordinates[3], Stop::GEOFACTORY.srid))}
    end
    page = params[:page] || 0
    @stops = @stops.page(page)
    render json: @stops, meta: { total: @stops.count, page: page, per_page: Stop.default_per_page }
  end

  def show
    render json: @stop
  end

  def create
    @stop = Stop.new(stop_params)
    @stop.save!
    render json: @stop
  end

  def update
    @stop.update(stop_params)
    render json: @stop, status: :ok
  end

  def destroy
    @stop.destroy!
    render json: @stop, status: :ok
  end

  private

  def set_stop
    @stop = Stop.find_by!(onestop_id: params[:id])
  end

  def stop_params
    params.require(:stop).permit! # TODO: actually limit parameters
  end
end
