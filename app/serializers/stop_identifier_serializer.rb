class StopIdentifierSerializer < ApplicationSerializer
  attributes :identifier,
             :tags,
             :created_at,
             :updated_at
end
