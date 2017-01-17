module OldTrackedByChangeset
  extend ActiveSupport::Concern

  included do
    belongs_to :created_or_updated_in_changeset, class_name: 'Changeset'
    belongs_to :destroyed_in_changeset, class_name: 'Changeset'

    belongs_to :current, class_name: self.to_s.gsub('Old', '')
  end

  def before_update_making_history(changeset)
    return true
  end

  def update_associations(changeset)
    return true
  end

  def before_destroy_making_history(changeset)
    return true
  end
end
