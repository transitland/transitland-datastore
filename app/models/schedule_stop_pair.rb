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
#  wheelchair_accessible              :integer
#  bikes_allowed                      :integer
#  pickup_type                        :integer
#  drop_off_type                      :integer
#  timepoint                          :integer
#  shape_dist_traveled                :float
#
# Indexes
#
#  c_ssp_cu_in_changeset                            (created_or_updated_in_changeset_id)
#  c_ssp_destination                                (destination_id)
#  c_ssp_origin                                     (origin_id)
#  c_ssp_route                                      (route_id)
#  c_ssp_service_end_date                           (service_end_date)
#  c_ssp_service_start_date                         (service_start_date)
#  c_ssp_trip                                       (trip)
#  index_current_schedule_stop_pairs_on_updated_at  (updated_at)
#

class BaseScheduleStopPair < ActiveRecord::Base
  self.abstract_class = true
  PER_PAGE = 50
end

class ScheduleStopPair < BaseScheduleStopPair
  self.table_name_prefix = 'current_'

  # Relations to stops and routes
  belongs_to :origin, class_name: "Stop"
  belongs_to :destination, class_name: "Stop"
  belongs_to :route

  # Required relations and attributes
  validates :route, presence: true
  validates :destination, presence: true
  validates :route, presence: true
  validates :trip, presence: true
  
  # Check date ranges
  before_validation :set_service_range
  validates :service_start_date, presence: true
  validates :service_end_date, presence: true
  validate :validate_service_added_dates_range
  validate :validate_service_except_dates_range

  # Add scope for updated_since
  include UpdatedSince

  # Scopes
  # Service active on a date
  scope :where_service_on_date, -> (date) {
    date = date.is_a?(Date) ? date : Date.parse(date)
    # ISO week day is Monday = 1, Sunday = 7; Postgres arrays are indexed at 1
    where("(service_start_date <= ? AND service_end_date >= ?) AND (true = service_days_of_week[?] OR ? = ANY(service_added_dates)) AND NOT (? = ANY(service_except_dates))", date, date, date.cwday, date, date)
  }

  # Current service, and future service, active from a date
  scope :where_service_from_date, -> (date) {
    date = date.is_a?(Date) ? date : Date.parse(date)
    where("service_end_date >= ?", date)
  }

  # Service trips_out in a bbox
  scope :where_origin_bbox, -> (bbox) {
    bbox_coordinates = bbox.split(',')
    # assert params[:bbox].split(',').length == 4
    stops = Stop.where{geometry.op('&&', st_makeenvelope(bbox_coordinates[0], bbox_coordinates[1], bbox_coordinates[2], bbox_coordinates[3], Stop::GEOFACTORY.srid))}
    where(origin_id: stops.ids)      
  }


  # Handle mapping from onestop_id to id
  def route_onestop_id=(value)
    self.route_id = Route.where(onestop_id: value).pluck(:id).first
  end

  def origin_onestop_id=(value)
    self.origin_id = Stop.where(onestop_id: value).pluck(:id).first
  end
 
  def destination_onestop_id=(value)
    self.destination_id = Stop.where(onestop_id: value).pluck(:id).first
  end
  
  def service_on_date?(date)
    date = Date.parse(date) unless date.is_a?(Date)
    # the -1 is because ISO week day is Monday = 1, Sunday = 7
    (service_start_date <= date) && (service_end_date >= date) && (service_days_of_week[date.cwday-1] == true || service_added_dates.include?(date)) && (!service_except_dates.include?(date))
  end

  # Service exceptions
  def service_except_dates=(dates)
    super(dates.map { |x| x.is_a?(Date) ? x : Date.parse(x) }.uniq)
  end

  def service_added_dates=(dates)
    super(dates.map { |x| x.is_a?(Date) ? x : Date.parse(x) }.uniq)
  end

  # Tracked by changeset
  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :relationship,
    virtual_attributes: [:origin_onestop_id, :destination_onestop_id, :route_onestop_id]
  })
  def self.find_by_attributes(attrs = {})
    if attrs[:id].present?
      find(attrs[:id])
    end    
  end
  
  private
  
  # Set a service range from service_added_dates, service_except_dates
  def set_service_range
    if service_start_date.nil?
      self.service_start_date = [service_except_dates.min, service_added_dates.min].min
    end
    if service_end_date.nil?
      self.service_end_date = [service_except_dates.max, service_added_dates.max].max
    end
    true
  end
  
  # Require service_added_dates to be in service range
  def validate_service_added_dates_range
    invalid = service_added_dates.reject {|x| (service_start_date <= x) && (service_end_date >= x)}
    if !invalid.empty?
      errors.add(:service_added_dates, "service_added_dates must be within service_start_date, service_end_date range")
    end
  end
  
  # Require service_except_dates to be in service range
  def validate_service_except_dates_range
    invalid = service_except_dates.reject {|x| (service_start_date <= x) && (service_end_date >= x)}
    if !invalid.empty?
      errors.add(:service_except_dates, "service_except_dates must be within service_start_date, service_end_date range")
    end
  end
  
end

class OldScheduleStopPair < BaseScheduleStopPair
  include OldTrackedByChangeset
  belongs_to :stop, polymorphic: true
end
