module CurrentTrackedByChangeset
  extend ActiveSupport::Concern

  included do
    belongs_to :created_or_updated_in_changeset, class_name: 'Changeset'
    has_many :old_versions, -> { order('version DESC') }, class_name: "Old#{self.to_s}", foreign_key: 'current_id'

    attr_accessor :marked_for_destroy_making_history,
                  :old_model_left_after_destroy_making_history
  end

  module ClassMethods
    attr_reader :kind_of_model_tracked,
                :virtual_attributes,
                :sticky_attributes

    def apply_change(changeset: nil, change: {}, action: nil, onestop_ids_to_merge: nil, cache: {})
      case action
      when 'createUpdate'
        apply_change_create_update(changeset: changeset, change: change, cache: cache)
      when 'destroy'
        apply_change_destroy(changeset: changeset, change: change, cache: cache)
      when 'changeOnestopID'
        apply_change_change_onestop_id(changeset: changeset, change: change, cache: cache)
      when 'merge'
        if onestop_ids_to_merge.nil?
          raise Changeset::Error.new(changeset: changeset, message: "Error: must provide an array of onestop ids to merge.")
        end
        apply_change_merge_onestop_ids(changeset: changeset, change: change, onestop_ids_to_merge: onestop_ids_to_merge, cache: {})
      else
        raise ArgumentError.new('an action must be supplied')
      end
    end

    def apply_change_create_update(changeset: nil, change: nil, cache: {})
      existing_model = find_existing_model(change)
      attrs_to_apply = apply_params(change, cache)
      unless !self.column_names.include?("edited_attributes") || changeset.nil? || changeset.import?
        attrs_to_apply.update({ edited_attributes: attrs_to_apply.keys.select { |a| self.sticky_attributes.include?(a) } })
      end
      if existing_model
        existing_model.update_making_history(changeset: changeset, new_attrs: attrs_to_apply)
      else
        new_model = self.create_making_history(changeset: changeset, new_attrs: attrs_to_apply)
      end
    end

    def after_change_onestop_id(changeset)
      # this is available for overriding in models
      super(changeset) if defined?(super)
      return true
    end

    def apply_change_change_onestop_id(changeset: nil, change: nil, cache: {})
      unless change.has_key?(:new_onestop_id)
        raise Changeset.Error.new(changeset, "could not find newOnestopId")
      end
      existing_model = find_by_onestop_id(change[:onestop_id])
      if existing_model
        existing_model.update_making_history(changeset: changeset, new_attrs: { onestop_id: change[:new_onestop_id] }, old_attrs: { action: 'change_onestop_id' })
        existing_model.after_change_onestop_id(change[:onestop_id], changeset)
      else
        raise Changeset::Error.new(changeset: changeset, message: "could not find a #{self.name} with Onestop ID of #{change[:onestop_id]} to change Onestop ID")
      end
    end

    def after_merge_onestop_ids(changeset)
      # this is available for overriding in models
      super(changeset) if defined?(super)
      return true
    end

    def apply_change_merge_onestop_ids(changeset: nil, change: nil, onestop_ids_to_merge: nil, cache: {})
      attrs_to_apply = apply_params(change, cache)
      merge_into_model = find_by_onestop_id(change[:onestop_id])
      if merge_into_model
        merge_into_model.update_making_history(changeset: changeset, new_attrs: attrs_to_apply)
      else
        merge_into_model = self.create_making_history(changeset: changeset, new_attrs: attrs_to_apply)
      end
      merge_into_model.after_merge_onestop_ids(onestop_ids_to_merge, changeset)
      onestop_ids_to_merge.each { |onestop_id|
        model_to_merge = self.find_by_onestop_id(onestop_id)
        model_to_merge.destroy_making_history(changeset: changeset, action: 'merge', current: merge_into_model)
      }
    end

    def apply_change_destroy(changeset: nil, change: nil, cache: {})
      existing_model = find_existing_model(change)
      if existing_model
        existing_model.destroy_making_history(changeset: changeset, action: 'destroy')
      else
        raise Changeset::Error.new(changeset, "could not find a #{self.name} with Onestop ID of #{attrs[:onestop_id]} to destroy")
      end
    end

    def apply_associations(changeset: nil, change: {}, action: nil, cache: {})
      existing_model = find_existing_model(change)
      return unless existing_model
      new_attrs = apply_params(change, cache)
      existing_model.merge_in_attributes(new_attrs)
      existing_model.update_associations(changeset)
    end

    def apply_params(params, cache={})
      # Filter changeset params
      params.select { |key, value| self.changeable_attributes.include?(key) }
    end

    def create_making_history(changeset: nil, new_attrs: {})
      self.transaction do
        # Create new model
        new_model = self.new(new_attrs)
        new_model.version = 1
        new_model.created_or_updated_in_changeset = changeset
        # Save
        new_model.save!
        new_model
      end
    end

    def find_existing_model(attrs = {})
      case @kind_of_model_tracked
      when :onestop_entity
        self.find_by_onestop_id(attrs[:onestop_id])
      when :relationship
        self.find_by_attributes(attrs)
      end
    end

    def instantiate_an_old_model
      Object.const_get("Old#{self.to_s}").new
    end

    def changeable_attributes
      # Allow editing of attribute, minus foreign keys and protected attrs
      # TODO: read directly from JSON schema?
      # Convert everything to symbol
      @changeable_attributes ||= (
        attribute_names.map(&:to_sym) +
        @virtual_attributes.map(&:to_sym) -
        @protected_attributes.map(&:to_sym) -
        reflections.values.map(&:foreign_key).map(&:to_sym) -
        [:id, :created_at, :updated_at, :version, :edited_attributes]
      )
    end

    private

    def current_tracked_by_changeset(kind_of_model_tracked: nil, virtual_attributes: [], protected_attributes: [], sticky_attributes: [])
      if [:onestop_entity, :relationship].include?(kind_of_model_tracked)
        @kind_of_model_tracked = kind_of_model_tracked
      else
        raise ArgumentError.new("must specify whether it's an entity or a relationship being tracked")
      end
      @virtual_attributes = virtual_attributes
      @protected_attributes = protected_attributes
      @sticky_attributes = sticky_attributes
    end
  end

  def attribute_sticks?(attribute)
    self.class.sticky_attributes.map(&:to_sym).include?(attribute) && self.edited_attributes.map(&:to_sym).include?(attribute)
  end

  def as_change(sticky: false)
    Hash[
      slice(*self.class.changeable_attributes)
      .reject { |k, v| attribute_sticks?(k.to_sym) && sticky }
      .map { |k, v| [k.to_s.camelize(:lower).to_sym, v] }
    ]
  end

  def before_destroy_making_history(changeset, old_model)
    # this is available for overriding in models
    super(changeset, old_model) if defined?(super)
    return true
  end

  def destroy_making_history(changeset: nil, old_attrs: {}, action: nil, current: nil)
    self.class.transaction do
      # Create old model
      old_model = self.class.instantiate_an_old_model
      old_model.assign_attributes(changeable_attributes_as_a_cloned_hash.update(old_attrs))
      old_model.version = self.version
      old_model.destroyed_in_changeset = changeset
      old_model.action = action unless action.nil?
      old_model.current = current if action.eql?('merge') && current
      # Update current model
      self.marked_for_destroy_making_history = true
      self.old_model_left_after_destroy_making_history = old_model
      # Before destroy
      proceed = (
        old_model.before_destroy_making_history(changeset) &&
        self.before_destroy_making_history(changeset, old_model)
      )
      # Save
      if proceed
        self.destroy!
        old_model.save!
      end
    end
  end

  def update_associations(changeset)
    # this is available for overriding in models
    super(changeset) if defined?(super)
    return true
  end

  def update_making_history(changeset: nil, new_attrs: {}, old_attrs: {})
    self.class.transaction do
      # Create old model
      old_model = self.class.instantiate_an_old_model
      old_model.assign_attributes(changeable_attributes_as_a_cloned_hash.update(old_attrs))
      old_model.version = self.version
      old_model.current = self
      # Update current model
      self.version ||= 1 # some entities had no version set
      self.version = self.version + 1
      self.merge_in_attributes(new_attrs)
      self.created_or_updated_in_changeset = changeset
      # Save
      old_model.save!
      self.save!
    end
  end

  def merge(other)
    # Merge another instance into self
    self.merge_in_attributes(other.changeable_attributes_as_a_cloned_hash)
  end

  def merge_in_attributes(new_attrs)
    # Merge attributes into self
    self.assign_attributes(
      HashHelpers::merge_hashes(
        existing_hash: self.changeable_attributes_as_a_cloned_hash,
        incoming_hash: new_attrs
      )
    )
  end

  def changeable_attributes_as_a_cloned_hash
    cloned_hash = self.attributes.clone
    cloned_hash = cloned_hash.symbolize_keys.slice(*self.class.changeable_attributes)
    cloned_hash
  end
end
