class StopSerializer < ApplicationSerializer
  attributes :onestop_id,
             :geometry,
             :name,
             :tags,
             :created_at,
             :updated_at,
             :stop_identifiers
end
