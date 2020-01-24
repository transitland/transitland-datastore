class AdditionalFviCounts < ActiveRecord::Migration
  def change
    rename_column :feed_version_gtfs_imports, :error_count, :skip_entity_error_count
    add_column :feed_version_gtfs_imports, :generated_count, :jsonb 
    add_column :feed_version_gtfs_imports, :skip_entity_reference_count, :jsonb 
    add_column :feed_version_gtfs_imports, :skip_entity_filter_count, :jsonb 
    add_column :feed_version_gtfs_imports, :skip_entity_marked_count, :jsonb 
    add_column :feed_version_gtfs_imports, :interpolated_stop_time_count, :integer
  end
end
