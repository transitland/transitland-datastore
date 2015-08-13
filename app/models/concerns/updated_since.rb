module UpdatedSince
  extend ActiveSupport::Concern

  included do
    scope :updated_since, -> (date) { 
      date = date.is_a?(Date) ? date : DateTime.parse(date)      
      where("updated_at >= ?", date)
    }
  end
end
