class Api::V1::OperatorsController < Api::V1::BaseApiController
  include Geojson
  include JsonCollectionPagination
  include DownloadableCsv

  before_action :set_operator, only: [:show]

  def index
    @operators = Operator.where('')

    if params[:identifier].present?
      @operators = @operators.with_identifier_or_name(params[:identifier])
    elsif params[:identifier_starts_with].present?
      @operators = @operators.with_identifer_starting_with(params[:identifier_starts_with])
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
    if params[:onestop_id].present?
      @operators = @operators.where(onestop_id: params[:onestop_id])
    end
    if params[:tag_key].present? && params[:tag_value].present?
      @operators = @operators.with_tag_equals(params[:tag_key], params[:tag_value])
    elsif params[:tag_key].present?
      @operators = @operators.with_tag(params[:tag_key])
    end

    per_page = params[:per_page].blank? ? Operator::PER_PAGE : params[:per_page].to_i

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @operators,
          Proc.new { |params| api_v1_operators_url(params) },
          params[:offset],
          per_page,
          params.slice(:identifier, :identifier_starts_with, :lat, :lon, :r, :bbox, :onestop_id, :tag_key, :tag_value)
        )
      end
      format.geojson do
        render json: Geojson.from_entity_collection(@operators)
      end
      format.csv do
        return_downloadable_csv(@operators, 'operators')
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
