require 'uri'

def dmfr(feeds)
  return {
    "$schema": "https://dmfr.transit.land/json-schema/dmfr.schema-v0.1.0.json",
    feeds: feeds.map { |feed|
      feed_json = {
        spec: feed.feed_format,
        id: feed.onestop_id,
        urls: feed.urls,
        license: {
          spdx_identifier: nil,
          url: feed.license_url,
          use_without_attribution: feed.license_use_without_attribution,
          create_derived_product: feed.license_create_derived_product,
          redistribute: feed.license_redistribute,
          commercial_use_allowed: nil,
          share_alike_optional: nil,
          attribution_text: feed.license_attribution_text,
          attribution_instructions: nil
        }
      }
      if feed.authorization.present?
        feed_json[:authorization] = feed.authorization.to_json
      end
      if feed.operators.count == 1
        feed_json[:feed_namespace_id] = feed.operators.first.onestop_id
      end
      if feed.feed_format == 'gtfs-rt'
        onestop_ids = feed.operators.map(&:feeds).flatten.reject { |f| f == feed }.map(&:onestop_id)
        feed_json[:associated_feeds] = onestop_ids
      end
      feed_json
    },
    license_spdx_identifier: "CC0-1.0"
  }
end

namespace :feed do
  namespace :dmfr do
    task :export_archive, [] => [:environment] do |t, args|
      feeds_by_domain = Hash.new { |h, k| h[k] = [] }

      Feed.where('').includes('operators').find_each do |feed|
        url = feed.url || feed.urls['realtime_vehicle_positions'] || feed.urls['realtime_trip_updates'] || feed.urls['realtime_alerts']
        url = url.split('#').first # remove hash portion for Transitland Style URLs
        url = url.split('?').first # remove query params
        url = url.split('&').first # remove random stuff
        host = URI.parse(url).host.downcase
        domain = host.start_with?('www.') ? host[4..-1] : host
        feeds_by_domain[domain] << feed
      end

      zipfile_name = "tmp/tlv1-dmfr-by-domain.zip"
      Zip.unicode_names = true
      Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
        feeds_by_domain.each do |domain, feeds|
          zipfile.get_output_stream("#{domain}.dmfr.json") do |f|
            dmfr_json = dmfr(feeds)
            f.write(JSON.pretty_generate(dmfr_json))
          end
        end
      end
    end
  end
end
