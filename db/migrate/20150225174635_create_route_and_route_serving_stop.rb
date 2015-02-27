class CreateRouteAndRouteServingStop < ActiveRecord::Migration
  def change
    create_table :current_routes do |t|
      t.string :onestop_id
      t.string :name
      # t.geometry :geometry, geographic: true ?????
      t.hstore :tags
      t.references :operator, index: true

      t.references :created_or_updated_in_changeset, index: { name: 'c_route_cu_in_changeset' }
      t.integer :version

      t.timestamps
    end

    create_table :old_routes do |t|
      t.string :onestop_id
      t.string :name
      # t.geometry :geometry, geographic: true ?????
      t.hstore :tags
      t.references :operator, index: true, polymorphic: true

      t.references :created_or_updated_in_changeset, index: { name: 'o_route_cu_in_changeset' }
      t.references :destroyed_in_changeset, index: { name: 'o_route_d_in_changeset' }
      t.references :current, index: true
      t.integer :version

      t.timestamps
    end

    create_table :current_routes_serving_stop do |t|
      t.references :route, index: true
      t.references :stop, index: true
      t.hstore     :tags

      t.references :created_or_updated_in_changeset, index: { name: 'c_rss_cu_in_changeset' }
      t.integer :version

      t.timestamps
    end

    create_table :old_routes_serving_stop do |t|
      t.references :route, index: true, polymorphic: true
      t.references :stop, index: true, polymorphic: true
      t.hstore     :tags

      t.references :created_or_updated_in_changeset, index: { name: 'o_rss_cu_in_changeset' }
      t.references :destroyed_in_changeset, index: { name: 'o_rss_d_in_changeset' }
      t.references :current, index: true
      t.integer :version

      t.timestamps
    end
  end
end
