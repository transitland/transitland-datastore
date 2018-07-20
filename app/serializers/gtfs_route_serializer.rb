class GTFSRouteSerializer < GTFSEntitySerializer
    attributes :route_id,
                :route_short_name,
                :route_long_name,
                :route_desc,
                :route_type,
                :route_url,
                :route_color,
                :route_text_color,
                :agency_id
                # :route_sort_order
    def geometry
        {}
    end
end
  