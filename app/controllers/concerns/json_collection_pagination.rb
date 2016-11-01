module JsonCollectionPagination
  extend ActiveSupport::Concern
  PER_PAGE ||= 50
  SERIALIZER = nil

  def paginated_json_collection(collection)
    # Meta
    per_page = sort_per_page
    offset = sort_offset
    include_total = sort_total
    meta = {
      sort_key: sort_key,
      sort_order: sort_order,
      offset: offset,
      per_page: per_page
    }

    # Reorder
    collection = sort_reorder(collection)

    # Setup prev/next links
    if ['false', '∞'].include?(per_page)
      data_on_page = collection.to_a
    else
      # Get the current page of results.
      #  Add +1 to limit to see if there is a next page.
      #  This will be dropped in the return.
      data = collection.offset(offset).limit(per_page+1).to_a
      # Previous and next page
      meta_prev = url_for(query_params.merge(meta).merge({
        offset: (offset - per_page) >= 0 ? (offset - per_page) : 0,
      }))
      meta_next = url_for(query_params.merge(meta).merge({
        offset: offset + per_page,
      }))
      (meta[:prev] = meta_prev) if offset > 0
      (meta[:next] = meta_next) if data.size > per_page
      # Slice data
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

  private

  def query_params
    params.slice()
  end

  def sort_key
    (params[:sort_key].presence || :id).to_sym
  end

  def sort_order
    params[:sort_order].to_s == 'desc' ? :desc : :asc
  end

  def sort_reorder(collection)
    key = sort_key
    fail ArgumentError.new('Invalid sort_key') unless collection.column_names.include?(key.to_s)
    collection.reorder(key => sort_order)
  end

  def sort_offset
    (params[:offset].presence || 0).to_i
  end

  def sort_per_page
    # per_page magic values: false, ∞
    per_page = params[:per_page].presence.to_s
    if ['false', '∞'].include?(per_page)
      per_page
    else
      # class default
      (per_page.presence || self.class::PER_PAGE).to_i
    end
  end

  def sort_total
    AllowFiltering.to_boolean(params[:total])
  end

end
