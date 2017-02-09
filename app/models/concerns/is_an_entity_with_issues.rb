module IsAnEntityWithIssues
  extend ActiveSupport::Concern
  included do
    has_many :entities_with_issues, as: :entity, dependent: :destroy
    has_many :issues, -> { distinct }, through: :entities_with_issues, source: :issue
  end
end
