module HasTags
  extend ActiveSupport::Concern

  included do
    scope :with_tag, -> (key) { where("tags ? '#{key}'") }
    scope :with_tag_equals, -> (key, value) { where("tags -> '#{key}' = '#{value}'") }
  end
end
