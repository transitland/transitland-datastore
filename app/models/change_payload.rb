# == Schema Information
#
# Table name: change_payloads
#
#  id           :integer          not null, primary key
#  payload      :json
#  changeset_id :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_change_payloads_on_changeset_id  (changeset_id)
#

class ChangePayload < ActiveRecord::Base
  include HasAJsonPayload

  belongs_to :changeset

  after_initialize :set_default_values
  validate :validate_payload

  onestop_id_format_proc = -> (onestop_id, expected_entity_type) do
    is_a_valid_onestop_id, onestop_id_errors = OnestopId.validate_onestop_id_string(onestop_id, expected_entity_type: expected_entity_type)
    raise JSON::Schema::CustomFormatError.new(onestop_id_errors.join(', ')) if !is_a_valid_onestop_id
  end
  JSON::Validator.schema_reader = JSON::Schema::Reader.new(accept_uri: false, accept_file: true)
  JSON::Validator.register_format_validator('operator-onestop-id', -> (onestop_id) {
    onestop_id_format_proc.call(onestop_id, 'operator')
  })
  JSON::Validator.register_format_validator('stop-onestop-id', -> (onestop_id) {
    onestop_id_format_proc.call(onestop_id, 'stop')
  })
  JSON::Validator.register_format_validator('feed-onestop-id', -> (onestop_id) {
    onestop_id_format_proc.call(onestop_id, 'feed')
  })
  JSON::Validator.register_format_validator('route-onestop-id', -> (onestop_id) {
    onestop_id_format_proc.call(onestop_id, 'route')
  })
  JSON::Validator.register_format_validator('vehicle-type', -> (vehicle_type) {
    if vehicle_type.is_a?(Integer) || vehicle_type.match(/\A\d+\z/)
      GTFS::Route::VEHICLE_TYPES.keys.map {|i| i.to_s.to_i }.include?(vehicle_type.to_i)
    else
      GTFS::Route::VEHICLE_TYPES.values.map { |s| s.to_s.parameterize('_') }.include?(vehicle_type.to_s)
    end
  })
  JSON::Validator.register_format_validator('sha1', -> (sha1) {
    !!sha1.match(/^[0-9a-f]{5,40}$/)
  })

  def apply!
    cache = {}
    entity_types = {
      feed: Feed,
      stop: Stop,
      stop_station: StopStation,
      stop_platform: StopPlatform,
      operator: Operator,
      route: Route,
      schedule_stop_pair: ScheduleStopPair
    }
    (payload_as_ruby_hash[:changes] || []).each do |change|
      (entity_types.keys & change.keys).each do |entity_type|
        entity_types[entity_type].apply_change(
          changeset: changeset,
          attrs: change[entity_type],
          action: change[:action],
          cache: cache
        )
      end
    end
  end

  def revert!
    if applied
      # TODO: write it
      raise Changeset::Error.new(self, "cannot revert. This functionality doesn't exist yet.")
    else
      raise Changeset::Error.new(self, 'cannot revert. This changeset has not been applied yet.')
    end
  end

  def set_default_values
    if self.new_record?
      self.payload ||= {changes:[]}
    end
  end

  def payload_validation_errors
    JSON::Validator.fully_validate(
      File.join(__dir__, 'json_schemas', 'changeset.json'),
      self.payload,
      errors_as_objects: true
    )
  end

  def validate_payload
    payload_validation_errors.each do |error|
      errors.add(:payload, error[:message])
    end
    binding.pry if errors.size > 0
  end

end
