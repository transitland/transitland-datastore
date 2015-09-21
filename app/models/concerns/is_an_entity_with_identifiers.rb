module IsAnEntityWithIdentifiers
  extend ActiveSupport::Concern

  included do
    attr_accessor :identified_by, :not_identified_by

    scope :with_identifier, -> (search_string) { where{identifiers.within(search_string)} }
    scope :with_identifier_or_name, -> (search_string) { where{(identifiers.within(search_string)) | (name =~ search_string)} }
    scope :with_identifier_starting_with, -> (search_string) { where("'|' || array_to_string(identifiers, '|') LIKE ?", "%|#{search_string}%") }

    def self.before_create_making_history(new_model, changeset)
      new_model.identifiers = new_model.identified_by
      true
    end
  end

  def before_update_making_history(changeset)
    current_identifiers = self.identifiers.try(:dup) || []
    identifiers_to_add = self.try(:identified_by) || []
    identifiers_to_remove = self.try(:not_identified_by) || []

    current_identifiers += identifiers_to_add if identifiers_to_add.length > 0
    current_identifiers -= identifiers_to_remove if identifiers_to_remove.length > 0

    current_identifiers.uniq!

    self.identifiers = current_identifiers

    true
  end
end
