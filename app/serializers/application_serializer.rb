class ApplicationSerializer < ActiveModel::Serializer
  self.root = false
  cached
end
