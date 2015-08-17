class AddAttributesForFeedReportCard < ActiveRecord::Migration
  def change
    add_column :feeds, :license_name, :string
    add_column :feeds, :license_url, :string
    add_column :feeds, :license_use_without_attribution, :string
    add_column :feeds, :license_create_derived_product, :string
    add_column :feeds, :license_redistribute, :string

    [:current_operators, :old_operators].each do |table|
      add_column table, :short_name, :string
      add_column table, :website, :string
      add_column table, :country, :string
      add_column table, :state, :string
      add_column table, :metro, :string
    end
  end
end
