class FeedsGoThroughChangesets < ActiveRecord::Migration
  def change
    drop_table :feeds

    [:current, :old].each do |version|
      create_table "#{version}_feeds" do |t|
        t.string :onestop_id
        t.string :url
        t.string :feed_format
        t.hstore :tags
        t.string :last_sha1
        t.datetime :last_fetched_at
        t.datetime :last_imported_at
        t.string :license_name
        t.string :license_url
        t.string :license_use_without_attribution
        t.string :license_create_derived_product
        t.string :license_redistribute
        t.integer :version
        t.timestamps

        case version
        when :current
          t.references :created_or_updated_in_changeset, index: true
        when :old
          t.references :current, index: true
          t.references :created_or_updated_in_changeset, index: true
          t.references :destroyed_in_changeset, index: true
        end
      end

      create_table "#{version}_operators_in_feed" do |t|
        t.string :gtfs_agency_id
        t.integer :version
        t.timestamps

        case version
        when :current
          t.references :operator, index: true
          t.references :feed, index: true
          t.references :created_or_updated_in_changeset, index: { name: 'current_oif' }
        when :old
          t.references :operator, polymorphic: true, index: true
          t.references :feed, polymorphic: true, index: true
          t.references :current, index: true
          t.references :created_or_updated_in_changeset, index: { name: 'old_oif' }
          t.references :destroyed_in_changeset, index: true
        end
      end
    end
  end
end
