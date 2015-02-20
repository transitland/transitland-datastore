class OldEntitySerializer < EntitySerializer
  attributes :created_or_updated_in_changeset_id,
             :destroyed_in_changeset_id
end
