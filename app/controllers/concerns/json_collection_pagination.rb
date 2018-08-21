module JsonCollectionPagination
  extend ActiveSupport::Concern
  MAX_PER_PAGE = nil
  PER_PAGE ||= 50

  def paginated_collection(collection)
    # Meta
    per_page = sort_per_page
    offset = sort_offset
    include_total = sort_total
    min_id = sort_min_id
    meta = {
      sort_key: sort_key,
      sort_order: sort_order,
      per_page: per_page,
    }
    qps = params.permit(query_params.keys)
    # disallowed = params.keys.map(&:to_sym) - query_params.keys - meta.keys - [:total, :controller, :action, :format]

    # Reorder
    collection = sort_reorder(collection)

    # Setup prev/next links
    if ['false', '∞'].include?(per_page)
      data_on_page = collection.to_a
    elsif min_id
      # Get the current page of results, +1 to limit to check next page
      data = collection.where('id > ?', min_id).limit(per_page+1).to_a
      data_on_page = data[0...per_page]
      meta[:sort_min_id] = min_id
      (meta[:next] = url_for(qps.merge(meta).merge(sort_min_id: data_on_page.last.try(:id)))) if data.size > per_page
    else
      # Get the current page of results.
      #  Add +1 to limit to see if there is a next page.
      #  This will be dropped in the return.
      data = collection.offset(offset).limit(per_page+1).to_a
      data_on_page = data[0...per_page]
      # Previous and next page
      meta[:offset] = offset
      meta_prev = url_for(qps.merge(meta).merge({
        offset: (offset - per_page) >= 0 ? (offset - per_page) : 0,
      }))
      meta_next = url_for(qps.merge(meta).merge({
        offset: offset + per_page,
      }))
      (meta[:prev] = meta_prev) if offset > 0
      (meta[:next] = meta_next) if data.size > per_page
    end

    if include_total
      total = collection.count
      (total = total.size) if total.is_a?(Hash)
      meta[:total] = total
    end
    # Return results + meta
    data_on_page = data_on_page.empty? ? collection.model.none : data_on_page
    {json: data_on_page, meta: meta}
  end

  def paginated_json_collection(collection)
    result = paginated_collection(collection)
    result[:adapter] = :json
    result
  end

  def paginated_geojson_collection(collection)
    result = paginated_collection(collection)
    result[:each_serializer] = GeoJSONSerializer
    result[:root] = :features
    result[:adapter] = :geo_json_adapter
    result
  end

  private

  def sort_key
    (params[:sort_key].presence || :id).to_sym
  end

  def sort_min_id
    params[:sort_min_id].presence ? params[:sort_min_id].to_i : nil
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
    per_page = params[:per_page].presence
    if per_page == 'false' || per_page == '∞'
      per_page = self.class::MAX_PER_PAGE || 'false'
    else
      per_page = (per_page || self.class::PER_PAGE).to_i
      per_page = [per_page, (self.class::MAX_PER_PAGE || per_page)].min
    end
    per_page
  end

  def sort_total
    AllowFiltering.to_boolean(params[:total])
  end

end
