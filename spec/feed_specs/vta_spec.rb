describe 'VTA', optional: true do
  context 'GTFSGraph' do
    it 'correctly assigned distances to schedule stop pairs containing stops repeated in its Route Stop Pattern' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_vta_1930705, import_level: 2)
      origin = @feed.imported_stops.find_by!(
        onestop_id: "s-9q9kf4gkqz-greatmall~maintransitcenter"
      )
      destination = @feed.imported_stops.find_by!(
        onestop_id: "s-9q9kf51txf-main~greatmallparkway"
      )
      route = @feed.imported_routes.find_by!(onestop_id: 'r-9q9k-66')
      trip = '1930705'
      first_found = @feed.imported_schedule_stop_pairs.where(
        destination: origin,
        route: route,
        trip: trip
      )
      second_found = @feed.imported_schedule_stop_pairs.where(
        origin: origin,
        destination: destination,
        route: route,
        trip: trip
      )
      ssp1 = first_found.first
      ssp2 = second_found.first
      expect(ssp2.destination_dist_traveled).to be > ssp1.origin_dist_traveled
    end
  end
end
