module EntityWithIdentifiers
  extend ActiveSupport::Concern

  included do
    has_many :identifiers, dependent: :destroy, as: :identified_entity
  end
end
