module IsAnEntityWithIdentifiers
  extend ActiveSupport::Concern

  included do
    scope :with_identifier, -> (search_string) { where{identifiers.within(search_string)} }
    scope :with_identifier_or_name, -> (search_string) { where{(identifiers.within(search_string)) | (name =~ search_string)} }
  end
end
