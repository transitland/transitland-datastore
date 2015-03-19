class Api::V1::OperatorsController < Api::V1::BaseApiController
  include Geojson
  include JsonCollectionPagination

  before_action :set_operator, only: [:show]

  def index
    @operators = Operator.includes(:identifiers).where('') # TODO: check performance against eager_load, joins, etc.

    if params[:identifier].present?
      @operators = @operators.with_identifier_or_name(params[:identifier])
    end
    if [params[:lat], params[:lon]].map(&:present?).all?
      point = Operator::GEOFACTORY.point(params[:lon], params[:lat])
      r = params[:r] || 100 # meters TODO: move this to a more logical place
      @operators = @operators.where{st_dwithin(geometry, point, r)}.order{st_distance(geometry, point)}
    end
    if params[:bbox].present? && params[:bbox].split(',').length == 4
      bbox_coordinates = params[:bbox].split(',')
      @operators = @operators.where{geometry.op('&&', st_makeenvelope(bbox_coordinates[0], bbox_coordinates[1], bbox_coordinates[2], bbox_coordinates[3], Operator::GEOFACTORY.srid))}
    end

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @operators,
          Proc.new { |params| api_v1_operators_url(params) },
          params[:offset],
          Operator::PER_PAGE
        )
      end
      format.geojson do
        render json: Geojson.from_entity_collection(@operators)
      end
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @operator }
      format.geojson { } # TODO: write this
    end
  end

  private

  def set_operator
    @operator = Operator.find_by_onestop_id!(params[:id])
  end
end
