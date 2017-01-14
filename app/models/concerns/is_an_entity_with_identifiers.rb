module IsAnEntityWithIdentifiers
  extend ActiveSupport::Concern

  included do
    scope :with_identifier, -> (search_string) { where{identifiers.within(search_string)} }
    scope :with_identifier_or_name, -> (search_string) { where{(identifiers.within(search_string)) | (name =~ search_string)} }
    scope :with_identifier_starting_with, -> (search_string) { where("'|' || array_to_string(identifiers, '|') LIKE ?", "%|#{search_string}%") }
  end

  def identified_by=(values)
    self.identifiers = (self.identifiers + values).uniq
  end

  def not_identified_by=(values)
    self.identifiers = (self.identifiers - values).uniq
  end
end
