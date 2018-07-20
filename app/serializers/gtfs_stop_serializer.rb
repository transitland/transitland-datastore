class GTFSStopSerializer < GTFSEntitySerializer
    attributes :stop_id,
                :stop_code,
                :stop_name,
                :stop_desc,
                :zone_id,
                :stop_url,
                :location_type,
                :stop_timezone,
                :wheelchair_boarding,
                :parent_station_id
end
  