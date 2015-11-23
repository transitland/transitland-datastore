module JsonCollectionPagination
  extend ActiveSupport::Concern
  PER_PAGE = 50

  def paginated_json_collection(collection, path_helper, offset, per_page, total, params)
    # Apply id as a default sort order;
    #   will append to any existing sort orders.
    collection = collection.order(:id)

    # Meta
    offset = (offset.presence || 0).to_i
    per_page = (per_page.presence || self.class::PER_PAGE).to_i
    total = total.present?
    meta = {
        offset: offset,
        per_page: per_page
    }
    meta[:total] = collection.count if total

    # Get the current page of results.
    #  Add +1 to limit to see if there is a next page.
    #  This will be dropped in the return.
    data = collection.offset(offset).limit(per_page+1).to_a

    # Previous and next page
    if offset > 0
      meta[:prev] = path_helper.call(params.merge({
        offset: (offset - per_page) >= 0 ? (offset - per_page) : 0,
        per_page: per_page,
        # total: total
      }))
    end
    if data.size > per_page
      meta[:next] = path_helper.call(params.merge({
        offset: offset + per_page,
        per_page: per_page,
        # total: total
      }))
    end

    # Return results + meta
    { json: data[0...per_page], meta: meta }
  end
end
