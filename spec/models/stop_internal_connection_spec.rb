# == Schema Information
#
# Table name: current_stop_internal_connections
#
#  id              :integer          not null, primary key
#  connection_type :string
#  tags            :hstore
#  stop_id         :integer
#  origin_id       :integer
#  destination_id  :integer
#  version         :integer
#  created_at      :datetime
#  updated_at      :datetime
#
# Indexes
#
#  index_current_stop_internal_connections_on_connection_type  (connection_type)
#  index_current_stop_internal_connections_on_destination_id   (destination_id)
#  index_current_stop_internal_connections_on_origin_id        (origin_id)
#  index_current_stop_internal_connections_on_stop_id          (stop_id)
#
