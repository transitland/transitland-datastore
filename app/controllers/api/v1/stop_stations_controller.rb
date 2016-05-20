# == Schema Information
#
# Table name: current_stops
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  geometry                           :geography({:srid geometry, 4326
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  name                               :string
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  identifiers                        :string           default([]), is an Array
#  timezone                           :string
#  last_conflated_at                  :datetime
#  type                               :string
#  parent_stop_id                     :integer
#
# Indexes
#
#  #c_stops_cu_in_changeset_id_index      (created_or_updated_in_changeset_id)
#  index_current_stops_on_geometry        (geometry)
#  index_current_stops_on_identifiers     (identifiers)
#  index_current_stops_on_onestop_id      (onestop_id)
#  index_current_stops_on_parent_stop_id  (parent_stop_id)
#  index_current_stops_on_tags            (tags)
#  index_current_stops_on_updated_at      (updated_at)
#

class Api::V1::StopStationsController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include AllowFiltering

  before_action :set_stop, only: [:show]

  def index
    @stops = Stop.where(type: 'Stop')
    @stops = @stops.includes{[
      stop_platforms,
      stop_egresss
    ]}

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @stops,
          Proc.new { |params| api_v1_stations_url(params) },
          params[:sort_key],
          params[:sort_order],
          params[:offset],
          params[:per_page],
          params[:total],
          params.slice(
          )
        )
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: StopStationSerializer.new(@stops).as_json
      end
    end
  end

  private

  def set_stop
    @stop = Stop.find_by_onestop_id!(params[:id])
  end
end
