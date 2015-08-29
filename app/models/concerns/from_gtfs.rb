module FromGTFS
  extend ActiveSupport::Concern
  included do
    def self.from_gtfs(entity)
      raise NotImplementedError
    end
  end
end
