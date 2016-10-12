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
    if self.class::SERIALIZER
      { json: data_on_page, meta: meta, each_serializer: self.class::SERIALIZER }
    else
      { json: data_on_page, meta: meta }
    end
  end

  def paginated_json_collection_new(collection, path_helper)
    collection = sort_collection(collection)

    # Meta
    per_page = sort_per_page
    offset = sort_offset
    include_total = sort_total
    meta = sort_meta

    if per_page
      data = collection.offset(offset).limit(per_page+1).to_a
      # Previous and next page
      if offset > 0
        meta[:prev] = path_helper.call(params.slice(*query_params).merge(meta).merge({
          offset: (offset - per_page) >= 0 ? (offset - per_page) : 0,
        }))
      end
      if data.size > per_page
        meta[:next] = path_helper.call(params.slice(*query_params).merge(meta).merge({
          offset: offset + per_page,
        }))
      end
      data_on_page = data[0...per_page]
    else
      data_on_page = collection
    end

    if include_total
      meta[:total] = collection.count
    end

    # Return results + meta
    if self.class::SERIALIZER
      { json: data_on_page, meta: meta, each_serializer: self.class::SERIALIZER }
    else
      { json: data_on_page, meta: meta }
    end
  end

  private

  def query_params
    ['asd']
  end

  def sort_key
    (params[:sort_key].presence || :id).to_sym
  end

  def sort_order
    params[:sort_order].to_s == 'desc' ? :desc : :asc
  end

  def sort_collection(collection)
    key = sort_key
    fail ArgumentError.new('Invalid sort_key') unless collection.column_names.include?(key.to_s)
    collection.reorder(key => sort_order)
  end

  def sort_meta
    {
      sort_key: sort_key,
      sort_order: sort_order,
      offset: sort_offset,
      per_page: sort_per_page
    }
  end

  def sort_offset
    (params[:offset].presence || 0).to_i
  end

  def sort_per_page
    per_page = (params[:per_page].presence || self.class::PER_PAGE).to_i
  end

  def sort_total
    AllowFiltering.to_boolean(params[:total])
  end

end
