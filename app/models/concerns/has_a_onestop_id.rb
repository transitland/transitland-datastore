module HasAOnestopId
  extend ActiveSupport::Concern

  included do
    validates :onestop_id, presence: true
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

  def onestop_id=(value)
    super(OnestopId.factory(self.class).new(string: value).to_s)
  end

  private

  def validate_onestop_id
    osid = OnestopId.factory(self.class).new(string: onestop_id)
    osid.errors.each do |error|
      errors.add(:onestop_id, error)
    end
  end
end
