module HasAOnestopId
  extend ActiveSupport::Concern

  included do
    validates :onestop_id, presence: true, uniqueness: true
    validate :onestop_id, :validate_onestop_id

    def self.current_from_old_reference(old_entity, find_method)
      unless ['merge', 'change_onestop_id'].exclude?(old_entity.action) || old_entity.current.nil?
        self.send(find_method, { onestop_id: old_entity.current.onestop_id })
      end
    end

    def self.find_by_onestop_id!(onestop_id)
      begin
        # TODO: make this case insensitive
        self.find_by!(onestop_id: onestop_id)
      rescue ActiveRecord::RecordNotFound
        result = self.current_from_old_reference(Object.const_get("Old#{self.name}").find_by!(onestop_id: onestop_id), :find_by!)
        fail ActiveRecord::RecordNotFound, "#{self.name}: #{onestop_id} has been destroyed." if result.nil?
        result
      end
    end

    def self.find_by_onestop_id(onestop_id)
      # TODO: make this case insensitive
      result = self.find_by(onestop_id: onestop_id)
      if result.nil?
        result = Object.const_get("Old#{self.name}").find_by(onestop_id: onestop_id)
        unless result.nil?
          result = self.current_from_old_reference(result, :find_by)
        end
      end
      result
    end

    def self.find_by_current_onestop_ids!(onestop_ids)
      # First query to check for missing id's
      # keep them in order
      missing = onestop_ids - self.where(onestop_id: onestop_ids).pluck(:onestop_id)
      fail ActiveRecord::RecordNotFound, "Couldn't find: #{missing.join(' ')}" if missing.size > 0
      # Second query as usual
      self.where(onestop_id: onestop_ids)
    end

    def self.find_by_current_onestop_ids(onestop_ids)
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
