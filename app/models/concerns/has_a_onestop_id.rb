module HasAOnestopId
  extend ActiveSupport::Concern

  included do
    validates :onestop_id, presence: true, uniqueness: { scope: :version }
    validate :onestop_id, :validate_onestop_id

    def self.find_by_onestop_id!(onestop_id)
      # TODO: make this case insensitive
      self.find_by!(onestop_id: onestop_id, current: true)
    end

    def self.find_by_onestop_id(onestop_id)
      # TODO: make this case insensitive
      self.find_by(onestop_id: onestop_id, current: true)
    end
  end

  private

  def onestop_id_prefix_for_this_object
    OnestopIdService::MODEL_TO_PREFIX[self.class]
  end

  def validate_onestop_id
    is_a_valid_onestop_id = true
    if !onestop_id.start_with?(onestop_id_prefix_for_this_object + OnestopIdService::COMPONENT_SEPARATOR)
      errors.add(:onestop_id, "must start with \"#{onestop_id_prefix_for_this_object + OnestopIdService::COMPONENT_SEPARATOR}\" as its 1st component")
      is_a_valid_onestop_id = false
    end
    if onestop_id.split('-').length != 3
      errors.add(:onestop_id, 'must include 3 components separated by hyphens ("-")')
      is_a_valid_onestop_id = false
    end
    if onestop_id.split('-').second.length == 0 || !!(onestop_id.split('-').second =~ /[^a-z\d]/)
      errors.add(:onestop_id, 'must include a valid geohash as its 2nd component, after "s-"')
      is_a_valid_onestop_id = false
    end
    if !!(onestop_id.split('-').third =~ /[^a-zA-Z\d]/)
      errors.add(:onestop_id, 'must include only letters and digits in its abbreviated name (the 3rd component)')
      is_a_valid_onestop_id = false
    end
    is_a_valid_onestop_id
  end
end
