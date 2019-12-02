# == Schema Information
#
# Table name: gtfs_fare_attributes
#
#  id                :integer          not null, primary key
#  fare_id           :string           not null
#  price             :float            not null
#  currency_type     :string           not null
#  payment_method    :integer          not null
#  transfer_duration :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  feed_version_id   :integer          not null
#  agency_id         :integer
#  transfers         :integer          not null
#
# Indexes
#
#  index_gtfs_fare_attributes_on_agency_id  (agency_id)
#  index_gtfs_fare_attributes_on_fare_id    (fare_id)
#  index_gtfs_fare_attributes_unique        (feed_version_id,fare_id) UNIQUE
#

class GTFSFareAttribute < ActiveRecord::Base
  include GTFSEntity
  belongs_to :feed_version
  belongs_to :agency, class_name: 'GTFSAgency'
  validates :agency, presence: true, unless: :skip_association_validations
  validates :feed_version, presence: true, unless: :skip_association_validations
  validates :fare_id, presence: true
  validates :price, presence: true
  validates :currency_type, presence: true
  validates :payment_method, presence: true
end
