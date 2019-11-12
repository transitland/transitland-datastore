# == Schema Information
#
# Table name: feed_versions
#
#  id                     :integer          not null, primary key
#  feed_id                :integer          not null
#  feed_type              :string           default("gtfs"), not null
#  file                   :string           default(""), not null
#  earliest_calendar_date :date             not null
#  latest_calendar_date   :date             not null
#  sha1                   :string           not null
#  md5                    :string
#  tags                   :hstore
#  fetched_at             :datetime         not null
#  imported_at            :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  import_level           :integer          default(0), not null
#  url                    :string           default(""), not null
#  file_raw               :string
#  sha1_raw               :string
#  md5_raw                :string
#  file_feedvalidator     :string
#  deleted_at             :datetime
#  sha1_dir               :string
#
# Indexes
#
#  index_feed_versions_on_earliest_calendar_date  (earliest_calendar_date)
#  index_feed_versions_on_feed_type_and_feed_id   (feed_type,feed_id)
#  index_feed_versions_on_latest_calendar_date    (latest_calendar_date)
#

FactoryGirl.define do
  factory :feed_version do
    sha1 { SecureRandom.hex(32) }
    earliest_calendar_date '2016-01-01'
    latest_calendar_date '2017-01-01'
    fetched_at '2015-12-01'
    imported_at '2016-01-01'
    feed

    factory :feed_version_recursosdatabuenosairesgobar do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/f-69y7-recursosdatabuenosairesgobar.zip'))}
      association :feed, factory: :feed_recursosdatabuenosairesgobar
    end

    factory :feed_version_caltrain do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/f-9q9-caltrain.zip')) }
      association :feed, factory: :feed_caltrain
    end

    factory :feed_version_bart do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/f-9q9-bart.zip')) }
      association :feed, factory: :feed_bart
    end

    factory :feed_version_vta_1930705 do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/vta-trip-1930705-gtfs.zip')) }
      association :feed, factory: :feed_vta
    end

    factory :feed_version_vta_1930691 do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/vta-trip-1930691-gtfs.zip')) }
      association :feed, factory: :feed_vta
    end

    factory :feed_version_vta_1965654 do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/vta-trip-1965654-gtfs.zip')) }
      association :feed, factory: :feed_vta
    end

    factory :feed_version_sfmta_6731593 do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/sfmta-trip-6731593.zip')) }
      association :feed, factory: :feed_sfmta
    end

    factory :feed_version_sfmta_6720619 do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/sfmta-trip-6720619.zip')) }
      association :feed, factory: :feed_sfmta
    end

    factory :feed_version_sfmta_7310245 do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/sfmta-trip-7310245.zip')) }
      association :feed, factory: :feed_sfmta
    end

    factory :feed_version_sfmta_7385783 do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/sfmta-trip-7385783.zip')) }
      association :feed, factory: :feed_sfmta
    end

    factory :feed_version_grand_river_1426033 do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/grand-river-trip-1426033.zip')) }
      association :feed, factory: :feed_grand_river
    end

    factory :feed_version_hdpt_shop_trip do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/hdpt_gtfs_shop.zip')) }
      association :feed, factory: :feed_hdpt
    end

    factory :feed_version_hdpt_sun_trip do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/hdpt_gtfs_sun2.zip')) }
      association :feed, factory: :feed_hdpt
    end

    factory :feed_version_pvta_trip do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/pvta_trip_gtfs.zip')) }
      association :feed, factory: :feed_pvta
    end

    factory :feed_version_nycdotsiferry do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/siferry-gtfs.zip')) }
      association :feed, factory: :feed_nycdotsiferry
    end

    factory :feed_version_mtanyctbusstatenisland_trip_YU_S6_Weekday_030000_MISC_112 do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/mtanyctbusstatenisland-trip-YU_S6-Weekday-030000_MISC_112.zip')) }
      association :feed, factory: :feed_mtanyctbusstatenisland
    end

    factory :feed_version_rome do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/rome-trip-754_4655513.zip')) }
      association :feed, factory: :feed_rome
    end

    factory :feed_version_nj_path do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/path-nj-us.zip')) }
      association :feed, factory: :feed_nj_path
    end

    factory :feed_version_wmata_75098 do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/wmata_trip_75098.zip')) }
      association :feed, factory: :feed_wmata
    end

    factory :feed_version_wmata_48587 do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/wmata-trip-48587.zip')) }
      association :feed, factory: :feed_wmata
    end

    factory :feed_version_cta_476113351107 do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/cta-trip-476113351107.zip')) }
      association :feed, factory: :feed_cta
    end

    factory :feed_version_trenitalia_56808573 do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/trenitalia-trip-56808573.zip')) }
      association :feed, factory: :feed_trenitalia
    end

    factory :feed_version_nj_path_last_stop_past_edge do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/path-nj-us-last-stop-past-edge.zip')) }
      association :feed, factory: :feed_nj_path
    end

    factory :feed_version_nj_path_first_stop_before_edge do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/path-nj-us-first-stop-before-edge.zip')) }
      association :feed, factory: :feed_nj_path
    end

    factory :feed_version_mbta_33884627 do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/mbta_trip_33884627.zip')) }
      association :feed, factory: :feed_mbta
    end

    factory :feed_version_marta_trip_5449755 do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/marta_trip_5449755.zip')) }
      association :feed, factory: :feed_marta
    end

    factory :feed_version_marta do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/marta-trip-5453552.zip')) }
      association :feed, factory: :feed_marta
    end

    factory :feed_version_ttc_34398377 do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/ttc-trip-34398377.zip')) }
      association :feed, factory: :feed_ttc
    end

    factory :feed_version_ttc_34360409 do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/ttc-trip-34360409.zip')) }
      association :feed, factory: :feed_ttc
    end

    factory :feed_version_alleghany do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/alleghany.zip')) }
      association :feed, factory: :feed_alleghany
    end

    factory :feed_version_example do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/example.zip')) }
      association :feed, factory: :feed_example
    end

    factory :feed_version_example_station do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/example-station.zip')) }
      association :feed, factory: :feed_example
    end

    factory :feed_version_example_no_shapes do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/example-no-shapes.zip')) }
      association :feed, factory: :feed_example
    end

    factory :feed_version_example_issues do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/example-issues.zip')) }
      association :feed, factory: :feed_example
    end

    factory :feed_version_example_update_add do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/example-update-add.zip')) }
    end

    factory :feed_version_example_update_delete do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/example-update-delete.zip')) }
    end

    factory :feed_version_example_trips_special_stop_times do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/example-trips-special-stop-times.zip')) }
      association :feed, factory: :feed_example
    end

    factory :feed_version_example_multiple_agency_id_same_operator do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/example-multiple-agency-id-same-operator.zip')) }
      association :feed, factory: :feed_example
      after :create do |feed_version, evaluator|
        feed = feed_version.feed
        operator = feed.operators_in_feed.first.operator
        feed_version.feed.operators_in_feed.create!(
          operator: operator,
          gtfs_agency_id: 'DTA2'
        )
      end
    end

    factory :feed_version_seattle_childrens do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/seattle-childrens.zip')) }
      association :feed, factory: :feed_seattle_childrens
    end
  end
end
