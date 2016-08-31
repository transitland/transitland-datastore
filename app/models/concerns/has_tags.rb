module HasTags
  extend ActiveSupport::Concern

  included do
    before_validation :before_validation_compact_tags
    scope :with_tag, -> (key) { where("#{self.table_name}.tags ? '#{key}'") }
    scope :with_tag_equals, -> (key, value) { where("#{self.table_name}.tags -> '#{key}' = '#{value}'") }
    def before_validation_compact_tags
      self.tags.compact! if self.tags
    end
  end
end
