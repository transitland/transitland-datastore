describe OldTrackedByChangeset do
  class PseudoModel
    def self.belongs_to(one, two)
      true
    end
    include OldTrackedByChangeset
  end

  pending 'write some specs'
end
