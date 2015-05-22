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

class RouteServingStopSerializer < ApplicationSerializer
  attributes :operator_name,
             :operator_onestop_id,
             :route_name,
             :route_onestop_id

  def operator_name
    object.route.operator.name
  end

  def operator_onestop_id
    object.route.operator.onestop_id
  end

  def route_name
    object.route.name
  end

  def route_onestop_id
    object.route.onestop_id
  end
end
