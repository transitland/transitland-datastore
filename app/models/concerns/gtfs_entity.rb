module GTFSEntity
    extend ActiveSupport::Concern
    included do
        attr_accessor(:skip_association_validations)
    end
  end
  