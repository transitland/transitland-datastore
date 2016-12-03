class ApplicationSerializer < ActiveModel::Serializer
  # self.root = false
  include Rails.application.routes.url_helpers
end
