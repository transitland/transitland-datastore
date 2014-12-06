module IsAnEntityWithIdentifiers
  extend ActiveSupport::Concern

  included do
    has_many :identifiers, dependent: :destroy, as: :identified_entity

    scope :with_identifier, -> (identifier) { joins(:identifiers).where{identifiers.identifier =~ identifier} }
  end
end
