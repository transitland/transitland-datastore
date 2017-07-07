# == Schema Information
#
# Table name: current_routes_serving_stop
#
#  id                                 :integer          not null, primary key
#  route_id                           :integer
#  stop_id                            :integer
#  tags                               :hstore
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#
# Indexes
#
#  c_rss_cu_in_changeset                          (created_or_updated_in_changeset_id)
#  index_current_routes_serving_stop_on_route_id  (route_id)
#  index_current_routes_serving_stop_on_stop_id   (stop_id)
#

class BaseRouteServingStop < ActiveRecord::Base
  self.abstract_class = true
end

class RouteServingStop < BaseRouteServingStop
  self.table_name_prefix = 'current_'
  belongs_to :stop
  belongs_to :route

  validates :stop, presence: true
  validates :route, presence: true

  include CurrentTrackedByChangeset
  current_tracked_by_changeset kind_of_model_tracked: :relationship

  def self.find_by_attributes(attrs = {})
    if attrs.keys.include?(:route_onestop_id) && attrs.keys.include?(:stop_onestop_id)
      route = Route.find_by_onestop_id!(attrs[:route_onestop_id])
      stop = Stop.find_by_onestop_id!(attrs[:stop_onestop_id])
      find_by(route: route, stop: stop)
    else
      raise ArgumentError.new('must specify Onestop IDs for an route and for a stop')
    end
  end

  def before_destroy_making_history(changeset, old_model)
    if Stop.exists?(self.stop.id) && !self.stop.marked_for_destroy_making_history
      old_model.stop = self.stop
    elsif self.stop.old_model_left_after_destroy_making_history.present?
      old_model.stop = self.stop.old_model_left_after_destroy_making_history
    else
      raise 'about to create a broken OldRouteServingStop record'
    end

    if Route.exists?(self.route.id) && !self.route.marked_for_destroy_making_history
      old_model.route = self.route
    elsif self.route.old_model_left_after_destroy_making_history.present?
      old_model.route = self.route.old_model_left_after_destroy_making_history
    else
      raise 'about to create a broken OldRouteServingStop record'
    end
  end
end

class OldRouteServingStop < BaseRouteServingStop
  include OldTrackedByChangeset

  belongs_to :stop, polymorphic: true
  belongs_to :route, polymorphic: true
end
