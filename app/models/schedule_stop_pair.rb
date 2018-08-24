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
#  route_stop_pattern_id              :integer
#  origin_dist_traveled               :float
#  destination_dist_traveled          :float
#  feed_id                            :integer
#  feed_version_id                    :integer
#  frequency_type                     :string
#  frequency_headway_seconds          :integer
#
# Indexes
#
#  c_ssp_cu_in_changeset                                        (created_or_updated_in_changeset_id)
#  c_ssp_destination                                            (destination_id)
#  c_ssp_origin                                                 (origin_id)
#  c_ssp_route                                                  (route_id)
#  c_ssp_service_end_date                                       (service_end_date)
#  c_ssp_service_start_date                                     (service_start_date)
#  c_ssp_trip                                                   (trip)
#  index_current_schedule_stop_pairs_on_feed_id_and_id          (feed_id,id)
#  index_current_schedule_stop_pairs_on_feed_version_id_and_id  (feed_version_id,id)
#  index_current_schedule_stop_pairs_on_frequency_type          (frequency_type)
#  index_current_schedule_stop_pairs_on_operator_id_and_id      (operator_id,id)
#  index_current_schedule_stop_pairs_on_origin_departure_time   (origin_departure_time)
#  index_current_schedule_stop_pairs_on_route_stop_pattern_id   (route_stop_pattern_id)
#  index_current_schedule_stop_pairs_on_updated_at              (updated_at)
#

class BaseScheduleStopPair < ActiveRecord::Base
  self.abstract_class = true

  extend Enumerize
  enumerize :origin_timepoint_source, in: [
      :gtfs_exact,
      :gtfs_interpolated,
      :transitland_interpolated_linear,
      :transitland_interpolated_geometric,
      :transitland_interpolated_shape
    ]
  enumerize :destination_timepoint_source, in: [
      :gtfs_exact,
      :gtfs_interpolated,
      :transitland_interpolated_linear,
      :transitland_interpolated_geometric,
      :transitland_interpolated_shape
    ]
  enumerize :frequency_type, in: [
    :exact,
    :not_exact
  ]
end

class ScheduleStopPair < BaseScheduleStopPair
  self.table_name_prefix = 'current_'

  # Relations to stops and routes
  belongs_to :origin, class_name: "Stop"
  belongs_to :destination, class_name: "Stop"
  belongs_to :route
  belongs_to :operator
  belongs_to :route_stop_pattern
  belongs_to :feed
  belongs_to :feed_version

  # Required relations and attributes
  before_validation :filter_service_range
  validates :origin,
            :destination,
            :route,
            :operator,
            :trip,
            :origin_timezone,
            :destination_timezone,
            :origin_arrival_time,
            :origin_departure_time,
            :destination_arrival_time,
            :destination_departure_time,
            :service_start_date,
            :service_end_date,
            presence: true
  validates :frequency_start_time, presence: true, if: :frequency_type
  validates :frequency_end_time, presence: true, if: :frequency_type
  validates :frequency_headway_seconds, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :frequency_headway_seconds, presence: true, if: :frequency_type

  validate :validate_service_range
  validate :validate_service_exceptions


  # Add scope for updated_since
  include UpdatedSince

  # Scopes
  # Feed Version Import Level
  scope :where_import_level, -> (import_level) {
    where(feed_version: FeedVersion.where(import_level: import_level))
  }

  # Active Feed Version
  scope :where_imported_from_active_feed_version, -> {
    joins('INNER JOIN current_feeds ON feed_version_id = current_feeds.active_feed_version_id')
  }

  # Service active on a date
  scope :where_service_on_date, -> (date) {
    date = date.is_a?(Date) ? date : Date.parse(date)
    # ISO week day is Monday = 1, Sunday = 7; Postgres arrays are indexed at 1
    where("(service_start_date <= ? AND service_end_date >= ?) AND (true = service_days_of_week[?] OR ? = ANY(service_added_dates)) AND NOT (? = ANY(service_except_dates))", date, date, date.cwday, date, date)
  }

  scope :where_origin_departure_between, -> (time1, time2) {
    time1 = (GTFS::WideTime.parse(time1) || '00:00:00').to_s
    time2 = (GTFS::WideTime.parse(time2) || '99:59:59').to_s
    where("origin_departure_time >= ? AND origin_departure_time <= ?", time1, time2)
  }

  # Current service, and future service, active from a date
  scope :where_service_from_date, -> (date) {
    date = date.is_a?(Date) ? date : Date.parse(date)
    where("service_end_date >= ?", date)
  }

  scope :where_service_before_date, -> (date) {
    date = date.is_a?(Date) ? date : Date.parse(date)
    where("service_start_date <= ?", date)
  }

  # Service trips_out in a bbox
  scope :where_origin_bbox, -> (bbox) {
    stops = Stop.geometry_within_bbox(bbox)
    where(origin: stops)
  }

  # Handle mapping from onestop_id to id
  def route_onestop_id
    route.onestop_id
  end

  def route_onestop_id=(value)
    self.route = Route.find_by!(onestop_id: value)
    self.operator = route.operator
  end

  def route_stop_pattern_onestop_id
    route_stop_pattern.onestop_id
  end

  def origin_onestop_id
    origin.onestop_id
  end

  def origin_onestop_id=(value)
    self.origin = Stop.find_by!(onestop_id: value)
  end

  def destination_onestop_id
    destination.onestop_id
  end

  def destination_onestop_id=(value)
    self.destination = Stop.find_by!(onestop_id: value)
  end

  def route_stop_pattern_onestop_id=(value)
    self.route_stop_pattern = RouteStopPattern.find_by_onestop_id!(value)
  end

  def service_on_date?(date)
    date = Date.parse(date) unless date.is_a?(Date)
    # the -1 is because ISO week day is Monday = 1, Sunday = 7
    date.between?(service_start_date, service_end_date) && (service_days_of_week[date.cwday-1] == true || service_added_dates.include?(date)) && (!service_except_dates.include?(date))
  end

  # Service exceptions
  def service_except_dates=(dates)
    super(dates.map { |x| x.is_a?(Date) ? x : Date.parse(x) }.uniq)
  end

  def service_added_dates=(dates)
    super(dates.map { |x| x.is_a?(Date) ? x : Date.parse(x) }.uniq)
  end

  def origin_arrival_time=(value)
    super(GTFS::WideTime.parse(value))
  end

  def origin_departure_time=(value)
    super(GTFS::WideTime.parse(value))
  end

  def destination_arrival_time=(value)
    super(GTFS::WideTime.parse(value))
  end

  def destination_departure_time=(value)
    super(GTFS::WideTime.parse(value))
  end

  def frequency_start_time=(value)
    super(GTFS::WideTime.parse(value))
  end

  def frequency_end_time=(value)
    super(GTFS::WideTime.parse(value))
  end

  def expand_frequency
    return [self] unless frequency_start_time && frequency_end_time && frequency_headway_seconds
    o_a = GTFS::WideTime.parse(origin_arrival_time).to_seconds
    o_d = GTFS::WideTime.parse(origin_departure_time).to_seconds
    d_a = GTFS::WideTime.parse(destination_arrival_time).to_seconds
    d_d = GTFS::WideTime.parse(destination_departure_time).to_seconds
    e = GTFS::WideTime.parse(frequency_end_time).to_seconds
    t = 0
    ret = []
    while (o_a + t) <= e      
      a = self.dup
      a.origin_arrival_time = GTFS::WideTime.new(o_a + t).to_s
      a.origin_departure_time = GTFS::WideTime.new(o_d + t).to_s
      a.destination_arrival_time = GTFS::WideTime.new(d_a + t).to_s
      a.destination_departure_time = GTFS::WideTime.new(d_d + t).to_s
      ret << a
      t += frequency_headway_seconds
    end
    ret
  end

  def self.percentile(values, percentile)
    values_sorted = values.sort
    return nil if values.empty?
    return values.last if percentile == 1.0
    k = (percentile*(values_sorted.length-1)+1).floor - 1
    f = (percentile*(values_sorted.length-1)+1).modulo(1)
    return values_sorted[k] + (f * (values_sorted[k+1] - values_sorted[k]))
  end

  def self.headways(dates, w, departure_start=nil, departure_end=nil, departure_span=nil, headway_percentile=0.5)
    dates = Array.wrap(dates)
    fail Exception.new('must supply at least one date') unless dates.size > 0
    departure_start = GTFS::WideTime.parse(departure_start || '00:00').to_seconds
    departure_end = GTFS::WideTime.parse(departure_end || '1000:00').to_seconds
    departure_span = GTFS::WideTime.parse(departure_span).try(:to_seconds) || 0
    headways = Hash.new { |h,k| h[k] = [] }
    dates.each do |date|
      stop_pairs = Hash.new { |h,k| h[k] = [] }
      ScheduleStopPair
        .where(w)
        .where_service_on_date(date)
        .select([:id, :origin_id, :destination_id, :origin_arrival_time, :origin_departure_time, :destination_arrival_time, :destination_departure_time, :frequency_start_time, :frequency_end_time, :frequency_headway_seconds])
        .find_each do |ssp|
          ssp.expand_frequency.each do |ssp|
            t = GTFS::WideTime.parse(ssp.origin_arrival_time).to_seconds
            key = [ssp.origin_id, ssp.destination_id]
            stop_pairs[key] << t
          end
      end
      stop_pairs.each do |k,v|
        v = v.sort
        next unless (v.last - v.first) > departure_span
        v = v.select { |i| departure_start <= i && i <= departure_end }
        headways[k] += v[0..-2].zip(v[1..-1] || []).map { |a,b| b - a }.select { |i| i > 0 }
      end
    end
    sids = Stop.select([:id, :onestop_id]).where(id: headways.keys.flatten).map { |s| [s.id, s.onestop_id] }.to_h
    headways.map { |k,v| [k.map { |i| sids[i] }, percentile(v, headway_percentile) ]}.select { |k,v| v }.to_h
  end

  # Tracked by changeset
  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :relationship,
    virtual_attributes: [
      :origin_onestop_id,
      :destination_onestop_id,
      :route_onestop_id,
      :route_stop_pattern_onestop_id
    ]
  })
  def self.find_by_attributes(attrs = {})
    if attrs[:id].present?
      find(attrs[:id])
    end
  end
  def self.apply_params(params, changeset: nil)
    params = super(params)
    {
      origin_onestop_id: :origin,
      destination_onestop_id: :destination,
      route_onestop_id: :route,
      route_stop_pattern_onestop_id: :route_stop_pattern
    }.each do |k,v|
      next if params[k].nil?
      params[v] = OnestopId.find_current_and_old!(params[k])
    end
    params[:operator] = params[:route].operator if params[:route]
    params
  end

  # Interpolate
  def self.interpolate(ssps, method=:linear)
    groups = []
    group = []
    ssps.each do |ssp|
      group << ssp
      if ssp.destination_arrival_time
        groups << group
        group = []
      end
    end
    if method == :linear
      groups.each { |group| self.interpolate_linear(group) }
    else
      raise ArgumentError.new("Unknown interpolation method: #{method}")
    end
  end

  private

  def self.interpolate_linear(group)
    window_start = GTFS::WideTime.parse(group.first.origin_departure_time)
    window_end = GTFS::WideTime.parse(group.last.destination_arrival_time)
    fail StandardError.new("First stop in trip must have a departure time") unless window_start
    fail StandardError.new("Last stop in trip must have an arrival time") unless window_end
    duration = window_end.to_seconds - window_start.to_seconds
    step = duration / group.size.to_f
    current = window_start.to_seconds
    # Set first/last stop
    group.first.origin_timepoint_source = :gtfs_exact
    group.first.window_start = window_start
    group.first.window_end = window_end
    group.last.destination_timepoint_source = :gtfs_exact
    group.last.window_start = window_start
    group.last.window_end = window_end
    # Interpolate
    group[0..-2].zip(group[1..-1]) do |a,b|
      current += step
      t = GTFS::WideTime.new(current.to_i).to_s
      #
      a.window_start = window_start
      a.window_end = window_end
      a.destination_arrival_time = t
      a.destination_departure_time = t
      a.destination_timepoint_source = :transitland_interpolated_linear
      # Next stop
      b.window_start = window_start
      b.window_end = window_end
      b.origin_arrival_time = t
      b.origin_departure_time = t
      b.origin_timepoint_source = :transitland_interpolated_linear
    end
  end

  # Set a service range from service_added_dates, service_except_dates
  def expand_service_range
    self.service_start_date ||= (service_except_dates + service_added_dates).min
    self.service_end_date ||= (service_except_dates + service_added_dates).max
    true
  end

  def filter_service_range
    expand_service_range
    self.service_added_dates = service_added_dates.select { |x| x.between?(service_start_date, service_end_date)}.sort
    self.service_except_dates = service_except_dates.select { |x| x.between?(service_start_date, service_end_date)}.sort
  end

  # Make sure service_start_date < service_end_date
  def validate_service_range
    if service_start_date && service_end_date
      errors.add(:service_start_date, "service_start_date begins after service_end_date") if service_start_date > service_end_date
    end
  end

  # Require service_added_dates to be in service range
  def validate_service_exceptions
    if !service_added_dates.reject { |x| x.between?(service_start_date, service_end_date)}.empty?
      errors.add(:service_added_dates, "service_added_dates must be within service_start_date, service_end_date range")
    end
    if !service_except_dates.reject { |x| x.between?(service_start_date, service_end_date)}.empty?
      errors.add(:service_except_dates, "service_except_dates must be within service_start_date, service_end_date range")
    end
  end
end

class OldScheduleStopPair < BaseScheduleStopPair
  include OldTrackedByChangeset
  belongs_to :stop, polymorphic: true
end
