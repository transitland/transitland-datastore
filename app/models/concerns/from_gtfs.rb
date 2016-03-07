module FromGTFS
  extend ActiveSupport::Concern
  included do
    def self.from_gtfs(entity, attrs={})
      raise NotImplementedError
    end
  end
end
