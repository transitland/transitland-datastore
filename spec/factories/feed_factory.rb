# == Schema Information
#
# Table name: current_feeds
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string           not null
#  url                                :string
#  spec                               :string           default("gtfs"), not null
#  tags                               :hstore
#  last_fetched_at                    :datetime
#  last_imported_at                   :datetime
#  version                            :integer
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  created_or_updated_in_changeset_id :integer
#  geometry                           :geography({:srid geometry, 4326
#  active_feed_version_id             :integer
#  edited_attributes                  :string           default([]), is an Array
#  name                               :string
#  type                               :string
#  auth                               :jsonb            not null
#  urls                               :jsonb            not null
#  deleted_at                         :datetime
#  last_successful_fetch_at           :datetime
#  last_fetch_error                   :string           default(""), not null
#  license                            :jsonb            not null
#  other_ids                          :jsonb            not null
#  associated_feeds                   :jsonb            not null
#  languages                          :jsonb            not null
#  feed_namespace_id                  :string           default(""), not null
#  file                               :string           default(""), not null
#
# Indexes
#
#  index_current_feeds_on_active_feed_version_id              (active_feed_version_id)
#  index_current_feeds_on_auth                                (auth)
#  index_current_feeds_on_created_or_updated_in_changeset_id  (created_or_updated_in_changeset_id)
#  index_current_feeds_on_geometry                            (geometry) USING gist
#  index_current_feeds_on_onestop_id                          (onestop_id) UNIQUE
#  index_current_feeds_on_urls                                (urls)
#

FactoryGirl.define do
  factory :feed do
    sequence (:url) { |n| "http://www.ridemetro.org/News/Downloads/DataFiles/google_transit#{n}.zip" }
    onestop_id { Faker::OnestopId.feed }
    geometry { {
        "type": "Polygon",
        "coordinates": [
          [
            [
              -122.43438720703125,
              37.771393199665255
            ],
            [
              -122.43438720703125,
              37.79289719200161
            ],
            [
              -122.39988327026369,
              37.79289719200161
            ],
            [
              -122.39988327026369,
              37.771393199665255
            ],
            [
              -122.43438720703125,
              37.771393199665255
            ]
          ]
        ]
      }
    }
    version 1
  end

  factory :feed_caltrain, parent: :feed, class: Feed do
    onestop_id 'f-9q9-caltrain'
    url 'http://www.caltrain.com/Assets/GTFS/caltrain/GTFS-Caltrain-Devs.zip'
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Caltrain',
        onestop_id: 'o-9q9-caltrain',
        timezone: 'America/Los_Angeles',
        website: 'http://www.caltrain.com',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'caltrain-ca-us'
      )
    end
  end

  factory :feed_vta, parent: :feed, class: Feed do
    onestop_id 'f-9q9-vta'
    url 'http://www.vta.org/sfc/servlet.shepherd/document/download/069A0000001NUea'
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Santa Clara Valley Transportation Authority',
        onestop_id: 'o-9q9-vta',
        timezone: 'America/Los_Angeles',
        website: 'http://www.vta.org/',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'VTA'
      )
    end
  end

  factory :feed_sfmta, parent: :feed, class: Feed do
    onestop_id 'f-9q8y-sfmta'
    url 'http://archives.sfmta.com/transitdata/google_transit.zip'
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'San Francisco Municipal Transportation Agency',
        onestop_id: 'o-9q8y-sfmta',
        timezone: 'America/Los_Angeles',
        website: 'http://www.sfmta.com/',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'SFMTA'
      )
    end
  end

  factory :feed_bart, parent: :feed, class: Feed do
    onestop_id 'f-9q9-bart'
    url 'http://www.bart.gov/dev/schedules/google_transit.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Bay Area Rapid Transit',
        short_name: 'BART',
        onestop_id: 'o-9q9-bart',
        timezone: 'America/Los_Angeles',
        website: 'http://www.bart.gov',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'BART'
      )
    end
  end

  factory :feed_rome, parent: :feed, class: Feed do
    onestop_id 'f-sr2-datimuoviromait'
    url 'http://dati.muovi.roma.it/gtfs/google_transit.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Roma Servizi per la Mobilità s.r.l.',
        short_name: '',
        onestop_id: 'o-sr2-romaserviziperlamobilitsrl',
        timezone: 'Europe/Rome',
        website: 'http://www.agenziamobilita.roma.it',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'MOBILITA'
      )
    end
  end

  factory :feed_nycdotsiferry, parent: :feed, class: Feed do
    onestop_id 'f-dr5r7-nycdotsiferry'
    url 'http://www.nyc.gov/html/dot/downloads/misc/siferry-gtfs.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'New York City Department of Transportation',
        short_name: 'NYC DOT',
        onestop_id: 'o-dr5r7-nycdot',
        timezone: 'America/New_York',
        website: 'http://nyc.gov/dot',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'NYC DOT'
      )
    end
  end

  factory :feed_mtanyctbusstatenisland, parent: :feed, class: Feed do
    onestop_id 'f-dr5r-mtanyctbusstatenisland'
    url 'http://web.mta.info/developers/data/nyct/bus/google_transit_staten_island.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'MTA New York City Transit',
        onestop_id: 'o-dr5r-nyct',
        timezone: 'America/New_York',
        website: 'http://www.google.com',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'MTA NYCT'
      )
    end
  end

  factory :feed_recursosdatabuenosairesgobar, parent: :feed, class: Feed do
    onestop_id 'f-69y7-recursosdatabuenosairesgobar'
    url 'http://recursos-data.buenosaires.gob.ar/ckan2/subte-gtfs/subte-gtfs.zip'
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Subterráneos de Buenos Aires',
        onestop_id: 'o-69y7-sbase',
        timezone: 'America/Argentina/Buenos_Aires',
        website: 'http://www.buenosaires.gob.ar/subte',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: '3'
      )
    end
  end

  factory :feed_nj_path, parent: :feed, class: Feed do
    onestop_id 'f-dr5r-panynjpath'
    url 'http://data.trilliumtransit.com/gtfs/path-nj-us/path-nj-us.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Port Authority Trans-Hudson',
        onestop_id: 'o-dr5r-path',
        timezone: 'America/New_York',
        website: 'http://www.panynj.gov/',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: '151'
      )
    end
  end

  factory :feed_example, parent: :feed, class: Feed do
    onestop_id 'f-9qs-example'
    url 'http://www.bart.gov/dev/schedules/google_transit.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Demo Transit Authority',
        onestop_id: 'o-9qs-demotransitauthority',
        timezone: 'America/Los_Angeles',
        website: 'http://www.google.com',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'DTA'
      )
    end
  end

  factory :feed_marta, parent: :feed, class: Feed do
    onestop_id 'f-dnh-marta'
    url 'http://www.itsmarta.com/google_transit_feed/google_transit.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Metropolitan Atlanta Rapid Transit Authority',
        onestop_id: 'o-dnh-metropolitanatlantarapidtransitauthority',
        timezone: 'America/New_York',
        website: 'http://www.google.com',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'MARTA'
      )
    end
  end

  factory :feed_mbta, parent: :feed, class: Feed do
    onestop_id 'f-drt-mbta'
    url 'http://www.mbta.com/uploadedfiles/MBTA_GTFS.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'MBTA',
        onestop_id: 'o-drt-mbta',
        timezone: 'America/New_York',
        website: 'http://www.google.com',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: '1'
      )
    end
  end

  factory :feed_grand_river, parent: :feed, class: Feed do
    onestop_id 'f-dpwz-grandrivertransit'
    url 'http://www.regionofwaterloo.ca/opendatadownloads/GRT_GTFS.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Grand River Transit',
        onestop_id: 'o-dpwz-grandrivertransit',
        timezone: 'America/New_York',
        website: 'http://www.grt.ca',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: nil
      )
    end
  end

  factory :feed_alleghany, parent: :feed, class: Feed do
    onestop_id 'f-dppc-alleganycountytransit'
    url 'http://mdtrip.org/googletransit/Allegany/google_transit.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Allegany County Transit',
        onestop_id: 'o-dppc-alleganycountytransit',
        timezone: 'America/New_York',
        website: 'http://gov.allconet.org/act',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'ACT'
      )
    end
  end

  factory :feed_hdpt, parent: :feed, class: Feed do
    onestop_id 'f-dnzft-harrisonburgdepartmentofpublictransportation'
    url 'https://www.harrisonburgva.gov/sites/default/files/Transit/google_transit.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Harrisonburg Department of Public Transportation',
        onestop_id: 'o-dnzft-harrisonburgdepartmentofpublictransportation',
        timezone: 'America/New_York',
        website: 'http://www.hdpt.com',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'HDPT'
      )
    end
  end

  factory :feed_pvta, parent: :feed, class: Feed do
    onestop_id 'f-drk-pvta'
    url 'http://www.pvta.com/g_trans/google_transit.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Pioneer Valley Transit Authority',
        onestop_id: 'o-drk-pvta',
        timezone: 'America/New_York',
        website: 'http://www.pvta.com',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'SATCo'
      )
    end
  end

  factory :feed_wmata, parent: :feed, class: Feed do
    onestop_id 'f-dqc-wmata'
    url 'http://lrg.wmata.com/GTFS_data/google_transit.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Washington Metropolitan Area Transit Authority',
        onestop_id: 'o-dqc-met',
        timezone: 'America/New_York',
        website: 'http://www.wmata.com/tripplanner',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'MET'
      )
    end
  end

  factory :feed_cta, parent: :feed, class: Feed do
    onestop_id 'f-dp3-cta'
    url 'http://www.transitchicago.com/downloads/sch_data/google_transit.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Chicago Transit Authority',
        onestop_id: 'o-dp3-chicagotransitauthority',
        timezone: 'America/Chicago',
        website: 'http://transitchicago.com',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: nil
      )
    end
  end

  factory :feed_trenitalia, parent: :feed, class: Feed do
    onestop_id 'f-sr-atac~romatpl~trenitalia'
    url 'http://dati.muovi.roma.it/gtfs/rome_static_gtfs.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Trenitalia',
        onestop_id: 'o-s-trenitalia',
        timezone: 'Europe/Rome',
        website: 'http://www.trenitalia.it',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'trenitalia'
      )
    end
  end

  factory :feed_ttc, parent: :feed, class: Feed do
    onestop_id 'f-dpz8-ttc'
    url 'http://opendata.toronto.ca/TTC/routes/OpenData_TTC_Schedules.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Toronto Transit Comission',
        onestop_id: 'o-dpz8-ttc',
        timezone: 'America/Toronto',
        website: 'http://www.ttc.ca',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: '1'
      )
    end
  end

  factory :feed_seattle_childrens, parent: :feed, class: Feed do
    onestop_id 'f-c23p1-seattlechildrenshospitalshuttle'
    url 'http://example.com/gtfs.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Seattle Children\'s Hospital Shuttle',
        onestop_id: 'o-c23p1-seattlechildrenshospitalshuttle',
        timezone: 'America/Los_Angeles',
        website: 'http://www.google.com',
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: '98'
      )
    end
  end
end
