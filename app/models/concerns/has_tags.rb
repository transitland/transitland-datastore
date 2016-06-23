module HasTags
  extend ActiveSupport::Concern

  included do
    scope :with_tag, -> (key) { where("#{self.table_name}.tags ? '#{key}'") }
    scope :with_tag_equals, -> (key, value) { where("#{self.table_name}.tags -> '#{key}' = '#{value}'") }
  end
end
