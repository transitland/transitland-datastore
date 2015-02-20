module HasAOnestopId
  extend ActiveSupport::Concern

  included do
    validates :onestop_id, presence: true, uniqueness: { scope: :version }
    validate :onestop_id, :validate_onestop_id

    def self.find_by_onestop_id!(onestop_id)
      # TODO: make this case insensitive
      self.find_by!(onestop_id: onestop_id)
    end

    def self.find_by_onestop_id(onestop_id)
      # TODO: make this case insensitive
      self.find_by(onestop_id: onestop_id)
    end
  end

  private

  def onestop_id_prefix_for_this_object
    OnestopId::ENTITY_TO_PREFIX[self.class.to_s.downcase]
  end

  def validate_onestop_id
    is_a_valid_onestop_id, onestop_id_errors = OnestopId.validate_onestop_id_string(self.onestop_id, expected_entity_type: self.class.to_s.downcase)
    onestop_id_errors.each do |onestop_id_error|
      errors.add(:onestop_id, onestop_id_error)
    end
    is_a_valid_onestop_id
  end
end
