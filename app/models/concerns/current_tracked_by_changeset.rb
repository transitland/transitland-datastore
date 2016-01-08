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
                :virtual_attributes

    def apply_change(changeset: nil, attrs: {}, action: nil, cache: {})
      existing_model = find_existing_model(attrs)
      case action
      when 'createUpdate'
        attrs_to_apply = apply_params(attrs, cache)
        if existing_model
          existing_model.update_making_history(changeset: changeset, new_attrs: attrs_to_apply)
        else
          create_making_history(changeset: changeset, new_attrs: attrs_to_apply)
        end
      when 'destroy'
        if existing_model
          existing_model.destroy_making_history(changeset: changeset)
        else
          raise Changeset::Error.new(changeset, "could not find a #{self.name} with Onestop ID of #{attrs[:onestop_id]} to destroy")
        end
      else
        raise ArgumentError.new('an action must be supplied')
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
          self.after_create_making_history(new_model, changeset)
          new_model
        end
      end
    end

    def after_create_making_history(created_model, changeset)
      # this is available for overriding in models
      super(created_model, changeset) if defined?(super)
      return true
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
      @changeable_attributes ||= (attribute_names + @virtual_attributes - reflections.values.map(&:foreign_key) - ['id', 'created_at', 'updated_at', 'created_or_updated_in_changeset_id', 'destroyed_in_changeset_id', 'version']).map(&:to_sym)
    end

    def changeable_associated_models
      @changeable_associated_models ||= (reflections.keys - [:created_or_updated_in_changeset, :destroyed_in_changeset])
    end

    private

    def current_tracked_by_changeset(kind_of_model_tracked: nil, virtual_attributes: [])
      if [:onestop_entity, :relationship].include?(kind_of_model_tracked)
        @kind_of_model_tracked = kind_of_model_tracked
      else
        raise ArgumentError.new("must specify whether it's an entity or a relationship being tracked")
      end
      @virtual_attributes = virtual_attributes
    end
  end

  def as_change
      Hash[
        slice(*self.class.changeable_attributes).
        map { |k,v| [k.to_s.camelize(:lower).to_sym,v] }
    ]
  end

  def before_destroy_making_history(changeset, old_model)
    # this is available for overriding in models
    super(changeset, old_model) if defined?(super)
    return true
  end

  def destroy_making_history(changeset: nil)
    self.class.transaction do
      old_model = self.class.instantiate_an_old_model
      old_model.assign_attributes(changeable_attributes_as_a_cloned_hash)
      old_model.version = self.version
      old_model.destroyed_in_changeset = changeset

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

  def merge_in_attributes(new_attrs)
    merged_attrs = HashHelpers::merge_hashes(
      existing_hash: self.changeable_attributes_as_a_cloned_hash,
      incoming_hash: new_attrs
    )
    self.assign_attributes(merged_attrs)
  end

  def changeable_attributes_as_a_cloned_hash
    cloned_hash = self.attributes.clone
    cloned_hash = cloned_hash.symbolize_keys.slice(*self.class.changeable_attributes)
    cloned_hash
  end
end
