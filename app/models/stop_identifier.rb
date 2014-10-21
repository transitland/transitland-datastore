# == Schema Information
#
# Table name: stop_identifiers
#
#  id              :integer          not null, primary key
#  stop_id         :integer
#  identifier_type :string(255)
#  identifier      :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#
# Indexes
#
#  index_stop_identifiers_on_stop_id  (stop_id)
#

class StopIdentifier < ActiveRecord::Base
  belongs_to :stop

  validates :identifier, presence: true, uniqueness: { scope: [:identifier_type, :stop] }
  validates :identifier_type, presence: true
end
