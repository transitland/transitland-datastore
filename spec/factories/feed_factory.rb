# == Schema Information
#
# Table name: current_feeds
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  url                                :string
#  feed_format                        :string
#  tags                               :hstore
#  last_fetched_at                    :datetime
#  last_imported_at                   :datetime
#  license_name                       :string
#  license_url                        :string
#  license_use_without_attribution    :string
#  license_create_derived_product     :string
#  license_redistribute               :string
#  version                            :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#  created_or_updated_in_changeset_id :integer
#  geometry                           :geography({:srid geometry, 4326
#  latest_fetch_exception_log         :text
#  license_attribution_text           :text
#  active_feed_version_id             :integer
#
# Indexes
#
#  index_current_feeds_on_active_feed_version_id              (active_feed_version_id)
#  index_current_feeds_on_created_or_updated_in_changeset_id  (created_or_updated_in_changeset_id)
#  index_current_feeds_on_geometry                            (geometry)
#

FactoryGirl.define do
  factory :feed do
    url 'http://www.ridemetro.org/News/Downloads/DataFiles/google_transit.zip'
    onestop_id { Faker::OnestopId.feed }
    version 1
  end

  factory :feed_caltrain, class: Feed do
    onestop_id 'f-9q9-caltrain'
    url 'http://www.caltrain.com/Assets/GTFS/caltrain/GTFS-Caltrain-Devs.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Caltrain',
        onestop_id: 'o-9q9-caltrain',
        timezone: 'America/Los_Angeles',
        website: 'http://www.caltrain.com',
        version: 1
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'caltrain-ca-us'
      )
    end
  end

  factory :feed_vta, class: Feed do
    onestop_id 'f-9q9-vta'
    url 'http://www.vta.org/sfc/servlet.shepherd/document/download/069A0000001NUea'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Santa Clara Valley Transportation Authority',
        onestop_id: 'o-9q9-vta',
        timezone: 'America/Los_Angeles',
        website: 'http://www.vta.org/',
        version: 1
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'VTA'
      )
    end
  end

  factory :feed_sfmta, class: Feed do
    onestop_id 'f-9q8y-sfmta'
    url 'http://archives.sfmta.com/transitdata/google_transit.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'San Francisco Municipal Transportation Agency',
        onestop_id: 'o-9q8y-sfmta',
        timezone: 'America/Los_Angeles',
        website: 'http://www.sfmta.com/',
        version: 1
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'SFMTA'
      )
    end
  end

  factory :feed_bart, class: Feed do
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
        version: 1
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'BART'
      )
    end
  end

  factory :feed_rome, class: Feed do
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
        version: 1
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'MOBILITA'
      )
    end
  end

  factory :feed_nycdotsiferry, class: Feed do
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
        version: 1
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'NYC DOT'
      )
    end
  end

  factory :feed_example, class: Feed do
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
        version: 1
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'DTA'
      )
    end
  end
end
