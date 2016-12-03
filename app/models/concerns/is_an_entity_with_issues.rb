module IsAnEntityWithIssues
  extend ActiveSupport::Concern
  included do
    has_many :entities_with_issues, as: :entity, dependent: :destroy
  end
end
