class FeedVersionInfoSerializer < ApplicationSerializer
  attributes :statistics,
             :scheduled_service,
             :filenames,
             :created_at,
             :updated_at
end
