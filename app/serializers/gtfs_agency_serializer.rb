# == Schema Information
#
# Table name: gtfs_agencies
#
#  id              :integer          not null, primary key
#  agency_id       :string           not null
#  agency_name     :string           not null
#  agency_url      :string           not null
#  agency_timezone :string           not null
#  agency_lang     :string           not null
#  agency_phone    :string           not null
#  agency_fare_url :string           not null
#  agency_email    :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  feed_version_id :integer          not null
#
# Indexes
#
#  index_gtfs_agencies_on_agency_id    (agency_id)
#  index_gtfs_agencies_on_agency_name  (agency_name)
#  index_gtfs_agencies_unique          (feed_version_id,agency_id) UNIQUE
#

class GTFSAgencySerializer < GTFSEntitySerializer
    attributes :agency_id, 
                :agency_name, 
                :agency_url, 
                :agency_timezone, 
                :agency_lang, 
                :agency_phone, 
                :agency_fare_url, 
                :agency_email
end
  
