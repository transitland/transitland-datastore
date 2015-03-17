module HashHelpers
  def self.merge_hashes(existing_hash: {}, incoming_hash: {})
    merged_hash = existing_hash.clone
    merged_hash.symbolize_keys!
    incoming_hash.symbolize_keys.each do |key, value|
      if value.nil? || ['', 'nil', 'null'].include?(value)
        merged_hash.delete(key)
      elsif merged_hash[key] == value
        next
      elsif key == :geometry
        # NOTE: we probably already have an RGeo::Geographic::SphericalPolygonImpl
        # existing internally, and a GeoJSON hash incoming
        merged_hash[key] = value
      elsif value.is_a?(Hash)
        merged_hash[key] = merge_hashes(existing_hash: (existing_hash[key] || {}), incoming_hash: value)
      elsif value.is_a?(Array)
        # NOTE: if an existing element isn't included in the
        # new array, it's effectively written over and removed
        merged_hash[key] = value
      else
        merged_hash[key] = value
      end
    end
    merged_hash
  end

  # borrowed from https://github.com/rails-api/active_model_serializers/issues/398#issuecomment-26072287
  def self.update_keys(existing_hash, method, *args)
    new_hash = existing_hash.clone
    new_hash.keys.each do |key|
      updated_key = key.to_s.send(method, *args).to_sym
      new_hash[updated_key] = new_hash.delete(key)
      case new_hash[updated_key]
      when Hash
        new_hash[updated_key] = update_keys(new_hash[updated_key], method, *args)
      when Array
        new_hash[updated_key].map! do |item_in_array|
          case item_in_array
          when Hash
            update_keys(item_in_array, method, *args)
          else
            item_in_array
          end
        end
      end
    end
    new_hash
  end
end
