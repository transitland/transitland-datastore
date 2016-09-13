module HasAOnestopId
  extend ActiveSupport::Concern

  included do
    validates :onestop_id, presence: true, uniqueness: true
    validate :onestop_id, :validate_onestop_id

    def self.find_by_onestop_id!(onestop_id)
      # TODO: make this case insensitive
      self.find_by!(onestop_id: onestop_id)
    end

    def self.find_by_onestop_id(onestop_id)
      # TODO: make this case insensitive
      self.find_by(onestop_id: onestop_id)
    end

    def self.find_by_onestop_ids!(onestop_ids)
      # First query to check for missing id's
      missing = onestop_ids - self.where(onestop_id: onestop_ids).pluck(:onestop_id)
      fail ActiveRecord::RecordNotFound, "Couldn't find: #{missing.join(' ')}" if missing.size > 0
      # Second query as usual
      self.where(onestop_id: onestop_ids)
    end

    def self.find_by_onestop_ids(onestop_ids)
      self.where(onestop_id: onestop_ids)
    end

  end

  private

  def validate_onestop_id
    osid = OnestopId.handler_by_model(self.class).new(string: onestop_id)
    osid.errors.each do |error|
      errors.add(:onestop_id, error)
    end
  end
end
