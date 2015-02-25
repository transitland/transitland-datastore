describe CurrentTrackedByChangeset do
  class PseudoModel
    def self.belongs_to(one, two)
      true
    end
    def self.has_many(one, two, three)
      true
    end
    include CurrentTrackedByChangeset
  end

  pending 'write some specs'
end
