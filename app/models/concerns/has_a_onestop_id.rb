module HasAOnestopId
  extend ActiveSupport::Concern

  included do
    validates :onestop_id, presence: true, uniqueness: true
    validate :onestop_id, :validate_onestop_id

    def self.find_by_current_and_old_onestop_id!(onestop_id)
      begin
        # TODO: make this case insensitive
        self.find_by!(onestop_id: onestop_id)
      rescue ActiveRecord::RecordNotFound
        result = Object.const_get("Old#{self.name}").find_by!(onestop_id: onestop_id)
        fail ActiveRecord::RecordNotFound, "#{self.name}: #{onestop_id} has been destroyed." if result.current.nil?
        result.current
      end
    end

    def self.find_by_current_and_old_onestop_id(onestop_id)
      # TODO: make this case insensitive
      result = self.find_by(onestop_id: onestop_id)
      if result.nil?
        old_entity = Object.const_get("Old#{self.name}").find_by(onestop_id: onestop_id)
        unless old_entity.nil?
          result = old_entity.current
        end
      end
      result
    end

    def self.find_by_onestop_id!(onestop_id)
      # TODO: make this case insensitive
      begin
        self.find_by!(onestop_id: onestop_id)
      rescue ActiveRecord::RecordNotFound => e
        fail ActiveRecord::RecordNotFound.new("Couldn't find #{self.name}: #{onestop_id}")
      end
    end

    def self.find_by_onestop_id(onestop_id)
      # TODO: make this case insensitive
      self.find_by(onestop_id: onestop_id)
    end

    def self.find_by_onestop_ids!(onestop_ids)
      # First query to check for missing id's
      # keep them in order
      missing = onestop_ids - self.where(onestop_id: onestop_ids).pluck(:onestop_id)
      fail ActiveRecord::RecordNotFound, "Couldn't find #{self.name}: #{missing.join(' ')}" if missing.size > 0
      # Second query as usual
      self.where(onestop_id: onestop_ids)
    end

    def self.find_by_onestop_ids(onestop_ids)
      self.where(onestop_id: onestop_ids)
    end
  end

  def generate_onestop_id
    fail NotImplementedError
  end

  private

  def validate_onestop_id
    osid = OnestopId.handler_by_model(self.class).new(string: onestop_id)
    osid.errors.each do |error|
      errors.add(:onestop_id, error)
    end
  end
end
