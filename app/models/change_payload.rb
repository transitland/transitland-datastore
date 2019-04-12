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

  ENTITY_TYPES = {
    feed: Feed,
    gtfs_realtime_feed: GTFSRealtimeFeed,
    stop: Stop,
    stop_platform: StopPlatform,
    stop_egress: StopEgress,
    operator: Operator,
    route: Route,
    schedule_stop_pair: ScheduleStopPair,
    route_stop_pattern: RouteStopPattern
  }

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
  JSON::Validator.register_format_validator('gtfs-realtime-feed-onestop-id', -> (onestop_id) {
    onestop_id_format_proc.call(onestop_id, 'gtfs_realtime_feed')
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

  def each_change
    (payload_as_ruby_hash[:changes] || []).each do |change|
      (ENTITY_TYPES.keys & change.keys).each do |entity_type|
        yield ENTITY_TYPES[entity_type], change[:action], change[entity_type], change[:onestop_ids_to_merge]
      end
    end
  end

  def apply_change
    self.each_change do |entity_cls, action, change, onestop_ids_to_merge|
      entity_cls.apply_change(
        changeset: changeset,
        action: action,
        change: change,
        onestop_ids_to_merge: onestop_ids_to_merge
      )
    end
  end

  def apply_associations
    self.each_change do |entity_cls, action, change, onestop_ids_to_merge|
      entity_cls.apply_associations(
        changeset: changeset,
        action: action,
        change: change
      )
    end
  end

  def revert!
    if applied
      # TODO: write it
      raise Changeset::Error.new(changeset: self, message: "cannot revert. This functionality doesn't exist yet.")
    else
      raise Changeset::Error.new(changeset: self, message: 'cannot revert. This changeset has not been applied yet.')
    end
  end

  def set_default_values
    if self.new_record?
      self.payload ||= {changes:[]}
    end
  end

  def payload_validation_errors
    filename = Rails.root.join('app', 'models', 'json_schemas', 'changeset.json').to_s
    JSON::Validator.fully_validate(
      filename,
      self.payload,
      errors_as_objects: true
    )
  end

  def validate_payload
    payload_validation_errors.each do |error|
      errors.add(:payload, error[:message])
    end
  end

  def resolving_and_deprecating_issues
    issues_to_resolve = []
    old_issues_to_deprecate = Set.new
    (payload_as_ruby_hash[:changes] || []).each do |change|
      (ENTITY_TYPES.keys & change.keys).each do |entity_type|
        issues_to_resolve += Issue.find(change[:issues_resolved]) if change.has_key?(:issues_resolved)
        if ENTITY_TYPES[entity_type].included_modules.include?(HasAOnestopId)
          action = change[:action]
          change = change[entity_type]
          if action.to_s.eql?("createUpdate")
            entity = ENTITY_TYPES[entity_type].find_by_current_and_old_onestop_id!(change[:onestop_id])
            old_issues_to_deprecate.merge(Issue.issues_of_entity(entity, entity_attributes: change.keys))
          end
        end
      end
    end
    [issues_to_resolve, old_issues_to_deprecate]
  end
end
