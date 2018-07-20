class Api::V1::GTFSFareRulesController < Api::V1::GTFSEntityController
    def self.model
      GTFSFareRule
    end
end
  class Api::V1::GTFSRoutesController < Api::V1::GTFSEntityController
    def self.model
      GTFSRoute
    end
end
  