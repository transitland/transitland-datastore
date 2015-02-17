class EntitySerializer < ApplicationSerializer
  attributes :current,
             :created_or_updated_in_changeset_id,
             :destroyed_in_changeset_id

  has_many :identifiers
end
