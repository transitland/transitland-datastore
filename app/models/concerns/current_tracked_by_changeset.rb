module CurrentTrackedByChangeset
  extend ActiveSupport::Concern

  included do
    belongs_to :created_or_updated_in_changeset, class_name: 'Changeset'
    has_many :old_versions, -> { order('version DESC') }, class_name: "Old#{self.to_s}"
  end

  module ClassMethods
    def apply_change(changeset: nil, attrs: {}, action: nil)
      case action
      when 'createUpdate'
        existing_model = self.find_by_onestop_id(attrs[:onestop_id])
        attrs_to_apply = attrs.select { |key, value| self.changeable_attributes.include?(key) }
        if existing_model
          existing_model.update_making_history(changeset: changeset, new_attrs: attrs_to_apply)
        else
          self.create_making_history(changeset: changeset, new_attrs: attrs_to_apply)
        end
      when 'destroy'
        existing_model = self.find_by_onestop_id!(attrs[:onestop_id])
        if existing_model
          existing_model.destroy_making_history(changeset: changeset)
        else
          raise Changeset::Error.new(changeset, "could not find a #{self.name} with Onestop ID of #{attrs[:onestop_id]} to destroy")
        end
      else
        raise ArgumentError.new('an action must be supplied')
      end
    end

    def create_making_history(changeset: nil, new_attrs: {})
      self.transaction do
        new_model = self.new(new_attrs)
        new_model.version = 1
        new_model.created_or_updated_in_changeset = changeset
        new_model.save!
        new_model
        # TODO: associated models
      end
    end

    def instantiate_an_old_model
      Object.const_get("Old#{self.to_s.capitalize}").new
    end

    def changeable_attributes
      @changeable_attributes ||= (self.attribute_names - ['id', 'created_at', 'updated_at', 'created_or_updated_in_changeset_id', 'destroyed_in_changeset_id', 'version']).map(&:to_sym)
    end

    def changeable_associated_models
      @changeable_associated_models ||= (self.reflections.keys - [:created_or_updated_in_changeset, :destroyed_in_changeset])
    end
  end

  def destroy_making_history(changeset: nil)
    self.class.transaction do
      old_model = self.class.instantiate_an_old_model
      old_model.assign_attributes(changeable_attributes_as_a_cloned_hash)
      old_model.version = self.version
      old_model.destroyed_in_changeset = changeset
      self.destroy! # cascade on to dependents??
      old_model.save!
      # TODO: associated models
    end
  end

  def update_making_history(changeset: nil, new_attrs: {})
    self.class.transaction do
      old_model = self.class.instantiate_an_old_model
      old_model.assign_attributes(changeable_attributes_as_a_cloned_hash)
      old_model.version = self.version
      old_model.current = self

      self.version = self.version + 1
      self.merge_in_attributes(new_attrs)
      self.created_or_updated_in_changeset = changeset

      # update associations!

      old_model.save!
      self.save!
      # TODO: associated models
    end
  end

  def merge_in_attributes(new_attrs)
    merged_attrs = HashHelpers::merge_hashes(
      existing_hash: self.changeable_attributes_as_a_cloned_hash,
      incoming_hash: new_attrs
    )
    self.assign_attributes(merged_attrs)
  end

  def changeable_attributes_as_a_cloned_hash
    cloned_hash = self.attributes.clone
    cloned_hash.symbolize_keys.slice!(*self.class.changeable_attributes)
    cloned_hash
  end
end
