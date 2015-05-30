module HasTags
  extend ActiveSupport::Concern

  included do
    scope :with_tag, -> (key, value) { where("tags -> '#{key}' = '#{value}'") }
  end
end
