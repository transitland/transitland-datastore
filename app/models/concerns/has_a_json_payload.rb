module HasAJsonPayload
  extend ActiveSupport::Concern

  included do
    after_update :clear_payload_as_ruby_hash
  end

  def payload_as_ruby_hash
    @payload_as_ruby_hash ||= HashHelpers::update_keys(payload, :underscore)
  end

  private

  def clear_payload_as_ruby_hash
    @payload_as_ruby_hash = nil
  end
end
