# == Schema Information
#
# Table name: gtfs_fare_attributes

class Api::V1::GTFSFareAttributesController < Api::V1::GTFSEntityController
    def self.model
      GTFSFareAttribute
    end
end
  