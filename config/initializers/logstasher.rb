if LogStasher.enabled?
  LogStasher.add_custom_fields do |fields|
    # This block is run in application_controller context,
    # so you have access to all controller methods
    params_to_log = [
      :changeset_id,
      :id,
      :offset,
      :per_page,
      :total,
      :bbox,
      :date,
      :destination_onestop_id,
      :feed_id,
      :feed_onestop_id,
      :feed_version_id,
      :feed_version_sha1,
      :import_level,
      :lat,
      :lon,
      :onestop_id,
      :operatedBy,
      :operator_onestop_id,
      :origin_departure_between,
      :origin_onestop_id,
      :r,
      :route_onestop_id,
      :service_from_date,
      :service_before_date,
      :tag_key,
      :tag_value,
      :trip,
      :updated_since
    ]

    params_to_log.each do |param_to_log|
      fields["#{param_to_log}_param".to_sym] = params[param_to_log]
    end

    # for the future:
    # fields[:user] = current_user && current_user.email
  end
end
