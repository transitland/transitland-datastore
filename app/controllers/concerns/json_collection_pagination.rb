module JsonCollectionPagination
  extend ActiveSupport::Concern

  def paginated_json_collection(collection, path_helper, offset, per_page = 50)
    if offset.blank?
      offset = 0
    else
      offset = offset.to_i
    end
    total = collection.count
    meta = {
        total: total,
        offset: offset,
        per_page: per_page
    }
    meta[:next] = path_helper.call(offset: offset + per_page) if is_there_a_next_page?(total, offset, per_page)
    meta[:prev] = path_helper.call(offset: offset - per_page) if is_there_a_prev_page?(total, offset, per_page)
    { json: collection.offset(offset).limit(per_page), meta: meta }
  end

  private

  def is_there_a_next_page?(total, offset, per_page)
    if total > per_page && per_page < (total - offset)
      true
    else
      false
    end
  end

  def is_there_a_prev_page?(total, offset, per_page)
    if total > per_page && offset >= per_page
      true
    else
      false
    end
  end
end
