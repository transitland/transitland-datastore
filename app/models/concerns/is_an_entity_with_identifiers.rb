module IsAnEntityWithIdentifiers
  extend ActiveSupport::Concern

  included do
    has_many :identifiers, dependent: :destroy, as: :identified_entity

    scope :with_identifier, -> (identifier) { joins(:identifiers).where{identifiers.identifier =~ identifier} }
    scope :with_identifier_or_name, -> (search_string) { joins{identifiers.outer}.where{(identifiers.identifier =~ search_string) | (name =~ search_string)} }
  end
end
