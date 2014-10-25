# == Schema Information
#
# Table name: stop_identifiers
#
#  id         :integer          not null, primary key
#  stop_id    :integer
#  identifier :string(255)
#  created_at :datetime
#  updated_at :datetime
#  tags       :hstore
#
# Indexes
#
#  index_stop_identifiers_on_stop_id  (stop_id)
#

class StopIdentifier < ActiveRecord::Base
  belongs_to :stop

  validates :identifier, presence: true, uniqueness: { scope: :stop }
end
