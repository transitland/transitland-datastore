# == Schema Information
#
# Table name: current_schedule_stop_pairs
#
#  id                                 :integer          not null, primary key
#  origin_id                          :integer
#  destination_id                     :integer
#  route_id                           :integer
#  trip                               :string
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  trip_headsign                      :string
#  origin_arrival_time                :string
#  origin_departure_time              :string
#  destination_arrival_time           :string
#  destination_departure_time         :string
#  frequency_start_time               :string
#  frequency_end_time                 :string
#  frequency_headway_seconds          :string
#  tags                               :hstore
#  service_start_date                 :date
#  service_end_date                   :date
#  service_added_dates                :date             default([]), is an Array
#  service_except_dates               :date             default([]), is an Array
#  service_days_of_week               :boolean          default([]), is an Array
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  block_id                           :string
#  trip_short_name                    :string
#  shape_dist_traveled                :float
#  origin_timezone                    :string
#  destination_timezone               :string
#  window_start                       :string
#  window_end                         :string
#  origin_timepoint_source            :string
#  destination_timepoint_source       :string
#  operator_id                        :integer
#  wheelchair_accessible              :boolean
#  bikes_allowed                      :boolean
#  pickup_type                        :string
#  drop_off_type                      :string
#  active                             :boolean
#
# Indexes
#
#  c_ssp_cu_in_changeset                                       (created_or_updated_in_changeset_id)
#  c_ssp_destination                                           (destination_id)
#  c_ssp_origin                                                (origin_id)
#  c_ssp_route                                                 (route_id)
#  c_ssp_service_end_date                                      (service_end_date)
#  c_ssp_service_start_date                                    (service_start_date)
#  c_ssp_trip                                                  (trip)
#  index_current_schedule_stop_pairs_on_operator_id            (operator_id)
#  index_current_schedule_stop_pairs_on_origin_departure_time  (origin_departure_time)
#  index_current_schedule_stop_pairs_on_updated_at             (updated_at)
#

class Api::V1::ScheduleStopPairsController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include DownloadableCsv
  include AllowFiltering

  before_action :set_schedule_stop_pairs

  def index
    respond_to do |format|
      format.json { render paginated_json_collection(@ssps) }
    end
  end

  private

  def query_params
    params.slice(
      :date,
      :service_from_date,
      :service_before_date,
      :origin_onestop_id,
      :destination_onestop_id,
      :origin_departure_between,
      :trip,
      :route_onestop_id,
      :route_stop_pattern_onestop_id,
      :operator_onestop_id,
      :bbox,
      :updated_since,
      :feed_version_sha1,
      :feed_onestop_id,
      :import_level,
      :imported_from_feed,
      :imported_from_feed_version
    )
  end

  def set_schedule_stop_pairs
    @ssps = ScheduleStopPair.where('')

    # Tags
    @ssps = AllowFiltering.by_tag_keys_and_values(@ssps, params)
    # Edges updated since
    @ssps = AllowFiltering.by_updated_since(@ssps, params)

    # Feed Version, or default: All active Feed Versions
    feed_version_sha1 = params[:feed_version_sha1].presence || params[:imported_from_feed_version].presence
    if feed_version_sha1
      @ssps = @ssps.where(feed_version: FeedVersion.find_by!(sha1: feed_version_sha1))
    end

    # Explicitly use active Feed Versions
    if params[:active].presence == 'true'
      @ssps = @ssps.where_imported_from_active_feed_version
    end
    # Feed
    feed_onestop_id = params[:feed_onestop_id].presence || params[:imported_from_feed].presence
    if feed_onestop_id
      @ssps = @ssps.where(feed: Feed.find_by_onestop_id!(feed_onestop_id))
    end
    # FeedVersion Import level
    if params[:import_level].present?
      @ssps = @ssps.where_import_level(AllowFiltering.param_as_array(params, :import_level))
    end
    # Service on a date
    if params[:date].presence == "today"
      @ssps = @ssps.where_service_on_date(tz_now.to_date)
    elsif params[:date].present?
      @ssps = @ssps.where_service_on_date(params[:date])
    end
    if params[:service_from_date].present?
      @ssps = @ssps.where_service_from_date(params[:service_from_date])
    end
    if params[:service_before_date].present?
      @ssps = @ssps.where_service_before_date(params[:service_before_date])
    end
    # Service between stops
    if params[:origin_onestop_id].present?
      origin_stops = Stop.find_by_onestop_ids!(AllowFiltering.param_as_array(params, :origin_onestop_id))
      @ssps = @ssps.where(origin: origin_stops)
    end
    if params[:destination_onestop_id].present?
      destination_stops = Stop.find_by_onestop_ids!(AllowFiltering.param_as_array(params, :destination_onestop_id))
      @ssps = @ssps.where(destination: destination_stops)
    end
    # Departing between...
    if params[:origin_departure_between].present?
      t1, t2 = AllowFiltering.param_as_array(params, :origin_departure_between)
      @ssps = @ssps.where_origin_departure_between(t1, t2)
    end
    # Service by trip id
    if params[:trip].present?
      @ssps = @ssps.where(trip: params[:trip])
    end
    # Service on a route
    if params[:route_onestop_id].present?
      routes = Route.find_by_onestop_ids!(AllowFiltering.param_as_array(params, :route_onestop_id))
      @ssps = @ssps.where(route: routes)
    end
    if params[:route_stop_pattern_onestop_id].present?
      rsps = RouteStopPattern.find_by_onestop_ids!(AllowFiltering.param_as_array(params, :route_stop_pattern_onestop_id))
      @ssps = @ssps.where(route_stop_pattern: rsps)
    end
    if params[:operator_onestop_id].present?
      operators = Operator.find_by_onestop_ids!(AllowFiltering.param_as_array(params, :operator_onestop_id))
      @ssps = @ssps.where(operator: operators)
    end
    # Stops in a bounding box
    if params[:bbox].present?
      @ssps = @ssps.where_origin_bbox(params[:bbox])
    end
    @ssps = @ssps.includes{[
      origin,
      destination,
      route,
      route_stop_pattern,
      operator,
      feed,
      feed_version
    ]}
  end

  private

  def tz_now
    tz_onestop_id = params[:origin_onestop_id].presence || params[:destination_onestop_id].presence || params[:operator_onestop_id].presence
    fail Exception.new('Must provide an origin_onestop_id, destination_onestop_id, or operator_onestop_id to use "now" or "today" relative times') unless tz_onestop_id
    tz_entity = OnestopId.find!(tz_onestop_id)
    TZInfo::Timezone.get(tz_entity.timezone).utc_to_local(DateTime.now)
  end

end
