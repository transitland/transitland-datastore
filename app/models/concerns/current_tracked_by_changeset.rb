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

    def apply_change(changeset: nil, attrs: {}, action: nil, cache: {})
      apply_changes(changeset: changeset, changes: [attrs], action: action, cache: cache)
    end

    def apply_changes(changeset: nil, changes: nil, action: nil, onestop_ids_to_merge: nil, cache: {})
      changes ||= []
      case action
      when 'createUpdate'
        apply_changes_create_update(changeset: changeset, changes: changes, cache: cache)
      when 'changeOnestopID'
        apply_changes_change_onestop_id(changeset: changeset, changes: changes, cache: cache)
      when 'merge'
        if onestop_ids_to_merge.nil?
          raise Changeset::Error.new(changeset: changeset, message: "Error: must provide an array of onestop ids to merge.")
        end
        apply_changes_merge_onestop_ids(changeset: changeset, change: changes.first, onestop_ids_to_merge: onestop_ids_to_merge, cache: {})
      when 'destroy'
        apply_changes_destroy(changeset: changeset, changes: changes, cache: cache)
      else
        raise ArgumentError.new('an action must be supplied')
      end
    end

    def apply_changes_create_update(changeset: nil, changes: nil, cache: {})
      new_models = []
      changes.each do |change|
        existing_model = find_existing_model(change)
        attrs_to_apply = apply_params(change, cache)
        unless !self.column_names.include?('edited_attributes') || changeset.nil? || changeset.import?
          attrs_to_apply.update({ edited_attributes: attrs_to_apply.keys.select { |a| self.sticky_attributes.include?(a) } })
        end
        if existing_model
          existing_model.update_making_history(changeset: changeset, new_attrs: attrs_to_apply)
        else
          new_model = self.create_making_history(changeset: changeset, new_attrs: attrs_to_apply)
          new_models << new_model if new_model
        end
      end
      new_models.each { |model| model.after_create_making_history(changeset) }
    end

    def apply_changes_change_onestop_id(changeset: nil, changes: nil, cache: {})
      changes.each do |change|
        unless change.has_key?(:new_onestop_id)
          raise Changeset.Error.new(changeset, "could not find newOnestopId")
        end
        existing_model = find_existing_model(change.merge({ onestop_id: change[:onestop_id] }))
        if existing_model
          attrs_to_apply = apply_params(existing_model.as_change.merge({ onestop_id: change[:new_onestop_id] }), cache)
          new_model = self.create_making_history(changeset: changeset, new_attrs: attrs_to_apply)
          new_model.after_create_making_history(changeset)
          existing_model.destroy_making_history(changeset: changeset, action: 'change_onestop_id')
        else
          raise Changeset::Error.new(changeset: changeset, message: "could not find a #{self.name} with Onestop ID of #{change[:onestop_id]} to change Onestop ID")
        end
      end
    end

    def apply_changes_merge_onestop_ids(changeset: nil, change: nil, onestop_ids_to_merge: nil, cache: {})
      attrs_to_apply = apply_params(change, cache)
      merge_into_model = find_by_onestop_id(change[:onestop_id])
      if merge_into_model
        merge_into_model.update_making_history(changeset: changeset, new_attrs: attrs_to_apply)
      else
        merge_into_model = self.create_making_history(changeset: changeset, new_attrs: attrs_to_apply)
        merge_into_model.after_create_making_history(changeset)
      end
      onestop_ids_to_merge.each { |onestop_id|
        model_to_merge = self.find_by_onestop_id(onestop_id)
        model_to_merge.destroy_making_history(changeset: changeset, action: 'merge', current: merge_into_model)
      }
    end

    def apply_changes_destroy(changeset: nil, changes: nil, cache: {})
      changes.each do |change|
        existing_model = find_existing_model(change)
        if existing_model
          case @kind_of_model_tracked
          when :onestop_entity
            existing_model.destroy_making_history(changeset: changeset, action: 'destroy')
          when :relationship
            existing_model.destroy_making_history(changeset: changeset)
          end
        else
          raise Changeset::Error.new(changeset: changeset, message: "could not find a #{self.name} with Onestop ID of #{change[:onestop_id]} to destroy")
        end
      end
    end

    def apply_params(params, cache={})
      # Filter changeset params
      params.select { |key, value| self.changeable_attributes.include?(key) }
    end

    def before_create_making_history(instantiated_model, changeset)
      # this is available for overriding in models
      super(instantiated_model, changeset) if defined?(super)
      return true
    end

    def create_making_history(changeset: nil, new_attrs: {})
      self.transaction do
        new_model = self.new(new_attrs)
        new_model.version = 1
        new_model.created_or_updated_in_changeset = changeset
        proceed = self.before_create_making_history(new_model, changeset) # handle associations
        if proceed
          new_model.save!
          new_model
        end
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

  def after_create_making_history(changeset)
    # this is available for overriding in models
    super(changeset) if defined?(super)
    return true
  end

  def before_destroy_making_history(changeset, old_model)
    # this is available for overriding in models
    super(changeset, old_model) if defined?(super)
    return true
  end

  def destroy_making_history(changeset: nil, action: nil, current: nil)
    self.class.transaction do
      old_model = self.class.instantiate_an_old_model
      old_model.assign_attributes(changeable_attributes_as_a_cloned_hash)
      old_model.version = self.version
      old_model.destroyed_in_changeset = changeset
      old_model.action = action unless action.nil?
      old_model.current = current if ['merge', 'change_onestop_id'].include?(action.to_s) && current

      self.marked_for_destroy_making_history = true
      self.old_model_left_after_destroy_making_history = old_model

      # handle any associations
      proceed = (
        old_model.before_destroy_making_history(changeset) &&
        self.before_destroy_making_history(changeset, old_model)
      )
      if proceed
        self.destroy!
        old_model.save!
      end
    end
  end

  def before_update_making_history(changeset)
    # this is available for overriding in models
    super(changeset) if defined?(super)
    return true
  end

  def update_making_history(changeset: nil, new_attrs: {})
    self.class.transaction do
      old_model = self.class.instantiate_an_old_model
      old_model.assign_attributes(changeable_attributes_as_a_cloned_hash)
      old_model.version = self.version
      old_model.current = self

      self.version ||= 1 # some entities had no version set
      self.version = self.version + 1
      self.merge_in_attributes(new_attrs)
      self.created_or_updated_in_changeset = changeset

      # handle any associations
      proceed = (
        old_model.before_update_making_history(changeset) &&
        self.before_update_making_history(changeset)
      )
      if proceed
        old_model.save!
        self.save!
      end
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
