module JsonCollectionPagination
  extend ActiveSupport::Concern
  PER_PAGE ||= 50
  SERIALIZER = nil

  def paginated_json_collection(collection, path_helper, sort_key, sort_order, offset, per_page, total, params)
    #changing from order to reorder to discard previous ordering
    sort_key = (sort_key.presence || :id).to_sym
    sort_order = sort_order.to_s == 'desc' ? :desc : :asc
    fail ArgumentError.new('Invalid sort_key') unless collection.column_names.include?(sort_key.to_s)
    collection = collection.reorder(sort_key => sort_order)

    # Meta
    offset = (offset.presence || 0).to_i
    include_total = (total == true || total == 'true')
    meta = {
        sort_key: sort_key,
        sort_order: sort_order,
        offset: offset
    }

    if [false, 'false', '∞'].include?(per_page)
      # allow pagination to be disabled
      # worst case: the query takes longer than 2 minutes and is
      # killed at the database and the load balancer
      meta[:per_page] = per_page
      data_on_page = collection
    else
      per_page = (per_page.presence || self.class::PER_PAGE).to_i
      meta[:per_page] = per_page
      # Get the current page of results.
      #  Add +1 to limit to see if there is a next page.
      #  This will be dropped in the return.
      data = collection.offset(offset).limit(per_page+1).to_a

      # Previous and next page
      if offset > 0
        meta[:prev] = path_helper.call(params.merge({
          sort_key: sort_key,
          sort_order: sort_order,
          offset: (offset - per_page) >= 0 ? (offset - per_page) : 0,
          per_page: per_page,
          total: total
        }))
      end
      if data.size > per_page
        meta[:next] = path_helper.call(params.merge({
          sort_key: sort_key,
          sort_order: sort_order,
          offset: offset + per_page,
          per_page: per_page,
          total: total
        }))
      end

      data_on_page = data[0...per_page]
    end

    if include_total
      meta[:total] = collection.count
    end

    # Return results + meta
    geojson = false
    result = { json: data_on_page, meta: meta }
    if geojson
      result[:each_serializer] = GeoJSONSerializer
      result[:root] = :features
    elsif self.class::SERIALIZER
      result[:each_serializer] = self.class::SERIALIZER
    end
    result
  end
end
