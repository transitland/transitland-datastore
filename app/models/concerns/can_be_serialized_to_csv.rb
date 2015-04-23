module CanBeSerializedToCsv
  extend ActiveSupport::Concern

  included do
    def self.to_csv
      CSV.generate do |csv|
        csv << (respond_to?(:csv_column_names) ? csv_column_names : column_names)
        find_each do |model|
          csv << (model.respond_to?(:csv_row_values) ? model.csv_row_values : model.attributes.values_at(*column_names))
        end
      end
    end
  end
end
